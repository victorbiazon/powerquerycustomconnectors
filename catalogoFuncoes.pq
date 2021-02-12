let
    tabelaFuncoes = Table.FromRecords(
        {
            [name = "alterarParametro", url = "https://raw.githubusercontent.com/victorbiazon/powerquerycustomconnectors/main/alterarParametro.pq"],
            [name = "exportaDadosProcessoMaestro", url = "https://raw.githubusercontent.com/victorbiazon/powerquerycustomconnectors/main/exportaDadosProcessoMaestro.pq"],
            [name = "exportaDadosDinamicoMaestro", url = "https://raw.githubusercontent.com/victorbiazon/powerquerycustomconnectors/main/exportaDadosDinamicoMaestro.pq"],
            [name = "exportaDadosCadastroDinamicoMaestro", url = "https://raw.githubusercontent.com/victorbiazon/powerquerycustomconnectors/main/exportaDadosCadastroDinamicoMaestro.pq"],
            [name = "exportaDadosDinamicoSOC", url = "https://raw.githubusercontent.com/victorbiazon/powerquerycustomconnectors/main/exportaDadosDinamicoSOC.pq"],
            [name = "exportaDadosDinamicoBSOC", url = "https://raw.githubusercontent.com/victorbiazon/powerquerycustomconnectors/main/exportaDadosDinamicoBSOC.pq"],
            [name = "getHubspotData", url = "https://raw.githubusercontent.com/victorbiazon/powerquerycustomconnectors/main/getHubspotData.pq"]
        }
    ),

    func =
    (
        funcao
    ) =>

    let
        url = Table.SelectRows(tabelaFuncoes, each [name] = funcao){0}[url],
        Fonte = Expression.Evaluate(
            Text.FromBinary(
                Web.Contents(url)
            ),
            #shared
        )
    in
        Fonte,
    
    Doc_func = 
        type function (
            funcao as (type text meta [
                Documentation.FieldCaption = "Função",
                Documentation.AllowedValues = tabelaFuncoes[name]
            ])
        ) as function meta Documentation_Metadata,

    //Documentação da função
    Documentation_Metadata = 
        [
            Documentation.Name = "catalogoFuncoes",
            Documentation.Description = "Função que retorna os conectores customizados do Power Query."/*,
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