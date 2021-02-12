let 
    //Código da função
    exportaDadosDinamico =
        (
            codigoProcesso,
            dataInicio,
            atualizar_data_fim,
            optional dataFim
        ) =>

        let
            parametro_data_inicio = "dt_inicio",
            parametro_data_fim = "dt_final",
            parametro = alterarParametro(
                alterarDatas(
                    "{'empresa':'1','codigo':'244','chave':'266e33d3f546cb5436a1','tipoSaida':'','senha':'d3BGJz2N','cd_processo':'','dt_inicio':'','dt_final':''}",
                    parametro_data_inicio,
                    parametro_data_fim,
                    dataInicio,
                    dataFim),
                "cd_processo",
                Text.From(codigoProcesso)
            ),
            filtra_data = true,
            limite_tempo = 90,
            Resultado = exportaDadosDinamicoPorData(
                parametro, 
                parametro_data_inicio, 
                parametro_data_fim, 
                limite_tempo, 
                atualizar_data_fim
            ),
            Resultado1 = 
                if Table.IsEmpty(Resultado)
                then Table.FromValue("Sem Resultado.")
                else let
                    listaColunas = Record.FieldNames(Resultado[Column1]{0}),
                    #"Column1 Expandido" = Table.ExpandRecordColumn(Resultado, "Column1", listaColunas, listaColunas),
                    #"Linhas Filtradas" = Table.SelectRows(#"Column1 Expandido", each [CODIGO ITEM PERSONALIZACAO] <> ""),
                    #"Personalização Adicionada" = Table.AddColumn(
                        #"Linhas Filtradas", 
                        "Código Item", 
                        each 
                            if Number.From([CODIGO ITEM PERSONALIZACAO]) < 10000 
                            then [CODIGO ITEM PERSONALIZACAO]
                            else Text.From(
                                Number.From(
                                    Text.End(
                                        Text.From([CODIGO ITEM PERSONALIZACAO]),
                                        4
                                    )
                                )
                            ),
                    type text
                    ),
                    #"Personalização Adicionada1" = Table.AddColumn(
                        #"Personalização Adicionada",
                        "Index",
                        each 
                            if Number.From([CODIGO ITEM PERSONALIZACAO]) > 10000 
                            then Number.From(
                                Text.Middle(
                                    Text.From([CODIGO ITEM PERSONALIZACAO]),
                                    0,
                                    Text.Length(
                                        Text.From([CODIGO ITEM PERSONALIZACAO])
                                    )-4
                                )
                            ) 
                            else 1,
                    Int64.Type
                    ),
                    #"Colunas Removidas" = Table.RemoveColumns(#"Personalização Adicionada1",{"CODIGO ITEM PERSONALIZACAO"}),
                    #"Colunas Mescladas" = Table.CombineColumns(#"Colunas Removidas",{"Código Item", "NOME ITEM PERSONALIZACAO"},Combiner.CombineTextByDelimiter("_", QuoteStyle.None),"NOME ITEM"),
                    #"Remover Duplicatas" = Table.Distinct(#"Colunas Mescladas"),
                    #"Colunas Personalização" = Table.Pivot(#"Remover Duplicatas", List.Distinct(#"Remover Duplicatas"[NOME ITEM]), "NOME ITEM", "RESPOSTA PERSONALIZACAO"),
                    #"Colunas Removidas1" = Table.RemoveColumns(#"Colunas Personalização",{"Index"}),
                    #"Colunas Renomeadas" = Table.TransformColumnNames(#"Colunas Removidas1", each if Text.Contains(_, "_") then Text.AfterDelimiter(_, "_") else _),
                    #"Colunas Reordenadas" = Table.ReorderColumns(#"Colunas Renomeadas",{"NUMERO", "PROCESSO ORIGEM", "ASSUNTO", "DIVISÃO", "DT CRIAÇÃO", "DT CONCLUSÃO", "SITUAÇÃO", "SOLICITANTE", "CLIENTE", "ULTIMA TAREFA"}),
                    #"Valor Substituído" = Table.ReplaceValue(#"Colunas Reordenadas","0",null,Replacer.ReplaceValue,{"PROCESSO ORIGEM"}),
                    #"Valor Substituído1" = Table.ReplaceValue(#"Valor Substituído","",null,Replacer.ReplaceValue,{"DT CONCLUSÃO"}),
                    #"Tipo Alterado" = Table.TransformColumnTypes(#"Valor Substituído1",{{"NUMERO", Int64.Type}, {"PROCESSO ORIGEM", Int64.Type}, {"ASSUNTO", type text}, {"DIVISÃO", type text}, {"DT CRIAÇÃO", type date}, {"DT CONCLUSÃO", type date}, {"SITUAÇÃO", type text}, {"SOLICITANTE", type text}, {"CLIENTE", type text}, {"ULTIMA TAREFA", type text}}),
                    #"Colunas Renomeadas1" = Table.RenameColumns(#"Tipo Alterado",{{"NUMERO", "Nº do Processo"}, {"PROCESSO ORIGEM", "Processo Origem"}, {"ASSUNTO", "Assunto Processo"}, {"DIVISÃO", "Divisão"}, {"DT CRIAÇÃO", "Data Criação"}, {"DT CONCLUSÃO", "Data Conclusão"}, {"SITUAÇÃO", "Situação"}, {"SOLICITANTE", "Solicitante"}, {"CLIENTE", "Cliente"}, {"ULTIMA TAREFA", "Última Tarefa"}})
                in
                    #"Colunas Renomeadas1"
        in
            Resultado1,
    

    //Documentação dos parâmetros
    Doc_func = 
        type function (
            codigoProcesso as (type number meta [
                Documentation.FieldCaption = "Código do Processo",
                Documentation.SampleValues = {"123"}
            ]),
            dataInicio as (type date meta [
                Documentation.FieldCaption = "Data Inicial",
                Documentation.SampleValues = {"dd/mm/aaaa"}
            ]),
            atualizar_data_fim as (type logical meta [
                Documentation.FieldCaption = "Atualiza data fim dinamicamente",
                Documentation.AllowedValues = {true, false}
            ]),
            optional dataFim as (type date meta [
                Documentation.FieldCaption = "Data Final",
                Documentation.SampleValues = {"dd/mm/aaaa"}
            ])
        ) as table meta Documentation_Metadata,

    //Documentação da função
    Documentation_Metadata = 
        [
            Documentation.Name = "exportaDadosProcessoMaestro",
            Documentation.Description = "Função que retorna o conteúdo de um Proesso do Maestro no período de datas informado.",
            Documentation.Examples = 
                {
                    [
                        Description = "Exporta Dados de processo com data fim definida",
                        Code = "exportaDadosDinamico(#(cr,lf,tab)123,#(tab)#(tab)//Código do Processo#(cr,lf,tab)01/10/2020,#(tab)//Data Inicial,#(cr,lf,tab)false,#(tab)#(tab)//Atualiza data fim dinamicamente#(cr,lf,tab)31/10/2020#(tab)//Data Final#(cr,lf))",
                        Result = "Lista de registros do resultado do Exporta Dados, conteúdo variável"
                    ],
                    [
                        Description = "Exporta Dados de processo com atualização dinamica de data fim definida",
                        Code = "exportaDadosDinamico(#(cr,lf,tab)123,#(tab)#(tab)//Código do Processo#(cr,lf,tab)01/10/2020,#(tab)//Data Inicial,#(cr,lf,tab)true,#(tab)#(tab)//Atualiza data fim dinamicamente#(cr,lf))",
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
            optional data_fim as date
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