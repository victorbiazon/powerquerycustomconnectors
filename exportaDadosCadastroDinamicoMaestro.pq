let 
    //Código da função
    exportaDadosDinamico =
        (
            codigoCadastro
        ) =>

        let
            parametro = alterarParametro(
                "{'empresa':'1','codigo':'140','chave':'f28b5d49b3020afeecd9','tipoSaida':'','codigocadastro':''}",
                "codigocadastro",
                Text.From(codigoCadastro)
            ),
            Resultado = exportaDados(parametro),
            Resultado1 = 
                if Table.IsEmpty(Resultado)
                then Table.FromValue("Sem Resultado")
                else
                    let
                        #"Column1 Expandido" = Table.ExpandRecordColumn(Resultado, "Column1", {"ATIVO", "DESCRICAO", "CODIGO"}, {"ATIVO", "DESCRICAO", "CODIGO"}),
                        #"Tipo Alterado" = Table.TransformColumnTypes(#"Column1 Expandido",{{"ATIVO", type text}, {"DESCRICAO", type text}, {"CODIGO", Int64.Type}}),
                        #"Colunas Reordenadas" = Table.ReorderColumns(#"Tipo Alterado",{"CODIGO", "ATIVO", "DESCRICAO"})
                    in
                        #"Colunas Reordenadas"
        in
            Resultado1,
    

    //Documentação dos parâmetros
    Doc_func = 
        type function (
            codigoCadastro as (type number meta [
                Documentation.FieldCaption = "Código do Cadastro",
                Documentation.SampleValues = {"123"}
            ])
        ) as table meta Documentation_Metadata,

    //Documentação da função
    Documentation_Metadata = 
        [
            Documentation.Name = "exportaDadosCadastroDinamicoMaestro",
            Documentation.Description = "Função que retorna os registros de um Cadastro Dinâmico do Maestro.",
            Documentation.Examples = 
                {
                    [
                        Description = "Execução da função",
                        Code = "exportaDadosDinamico(#(cr,lf,tab)123,#(tab)//Código do Cadastro Dinâmico#(cr,lf))",
                        Result = "Lista de registros do Cadastro Dinâmico"
                    ]
                }
        ],
    
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