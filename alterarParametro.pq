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