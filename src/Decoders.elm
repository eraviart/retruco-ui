module Decoders exposing (..)

import Dict exposing (Dict)
import Json.Decode exposing (..)
import Json.Decode.Extra exposing ((|:))
import String
import Types exposing (..)


ballotDecoder : Decoder Ballot
ballotDecoder =
    succeed Ballot
        |: oneOf [ (field "rating" int) |> andThen (\_ -> succeed False), succeed True ]
        |: (field "id" string)
        |: oneOf [ (field "rating" int), succeed 0 ]
        |: (field "statementId" string)
        |: oneOf [ (field "updatedAt" string), succeed "" ]
        |: (field "voterId" string)


bijectiveCardReferenceDecoder : Decoder BijectiveCardReference
bijectiveCardReferenceDecoder =
    succeed BijectiveCardReference
        |: (field "targetId" string)
        |: (field "reverseKeyId" string)


cardDecoder : Decoder Card
cardDecoder =
    succeed Card
        |: (field "createdAt" string)
        |: oneOf [ (field "deleted" bool), succeed False ]
        |: (field "id" string)
        |: (field "properties" (dict string))
        |: oneOf [ (field "rating" int), succeed 0 ]
        |: oneOf [ (field "ratingCount" int), succeed 0 ]
        |: oneOf [ (field "ratingSum" int), succeed 0 ]
        |: oneOf [ (field "references" (dict (list string))), succeed Dict.empty ]
        |: oneOf [ (field "subTypeIds" (list string)), succeed [] ]
        |: oneOf [ (field "tagIds" (list string)), succeed [] ]
        |: (field "type" string)
        |: oneOf [ (field "usageIds" (list string)), succeed [] ]


cardsAutocompletionBodyDecoder : Decoder CardsAutocompletionBody
cardsAutocompletionBodyDecoder =
    succeed CardsAutocompletionBody
        |: (field "data" (list cardsAutocompletionDecoder))


cardsAutocompletionDecoder : Decoder CardAutocompletion
cardsAutocompletionDecoder =
    succeed CardAutocompletion
        |: (field "autocomplete" string)
        |: (field "card" cardDecoder)
        |: (field "distance" float)


collectionDecoder : Decoder Collection
collectionDecoder =
    succeed Collection
        |: (field "authorId" string)
        |: oneOf [ (field "cardIds" (list string)), succeed [] ]
        |: oneOf [ (field "description" string), succeed "" ]
        |: (field "id" string)
        |: (maybe (field "logo" string)
                |> map
                    (\v ->
                        v
                            |> Maybe.andThen
                                (\s ->
                                    if String.isEmpty s then
                                        Nothing
                                    else
                                        Just s
                                )
                    )
           )
        |: (field "name" string)


dataIdBodyDecoder : Decoder DataIdBody
dataIdBodyDecoder =
    succeed DataIdBody
        |: (field "data" dataIdDecoder)


dataIdDecoder : Decoder DataId
dataIdDecoder =
    succeed DataId
        |: oneOf [ (field "ballots" (dict ballotDecoder)), succeed Dict.empty ]
        |: oneOf [ (field "cards" (dict cardDecoder)), succeed Dict.empty ]
        |: oneOf [ (field "collections" (dict collectionDecoder)), succeed Dict.empty ]
        |: (field "id" string)
        |: (oneOf [ (field "properties" (dict propertyDecoder)), succeed Dict.empty ])
        |: (oneOf [ (field "users" (dict userDecoder)), succeed Dict.empty ])
        |: oneOf [ (field "values" (dict valueDecoder)), succeed Dict.empty ]


dataIdsBodyDecoder : Decoder DataIdsBody
dataIdsBodyDecoder =
    succeed DataIdsBody
        |: oneOf [ (field "count" int), succeed 0 ]
        |: (field "data" dataIdsDecoder)
        |: oneOf [ (field "limit" int), succeed 0 ]
        |: oneOf [ (field "offset" int), succeed 0 ]


dataIdsDecoder : Decoder DataIds
dataIdsDecoder =
    map2 (,)
        (field "ids" (list string))
        (oneOf [ (field "users" (dict userDecoder)), succeed Dict.empty ])
        |> andThen
            (\( ids, users ) ->
                (if List.isEmpty ids then
                    succeed ( Dict.empty, Dict.empty, Dict.empty, Dict.empty, Dict.empty )
                 else
                    map5 (,,,,)
                        (oneOf [ (field "ballots" (dict ballotDecoder)), succeed Dict.empty ])
                        (oneOf [ (field "cards" (dict cardDecoder)), succeed Dict.empty ])
                        (oneOf [ (field "collections" (dict collectionDecoder)), succeed Dict.empty ])
                        (oneOf [ (field "properties" (dict propertyDecoder)), succeed Dict.empty ])
                        (oneOf [ (field "values" (dict valueDecoder)), succeed Dict.empty ])
                )
                    |> map
                        (\( ballots, cards, collections, properties, values ) ->
                            DataIds ballots cards collections ids properties users values
                        )
            )


messageBodyDecoder : Decoder String
messageBodyDecoder =
    (field "data" string)


popularTagDecoder : Decoder PopularTag
popularTagDecoder =
    succeed PopularTag
        |: (field "count" float)
        |: (field "tagId" string)


popularTagsDataDecoder : Decoder PopularTagsData
popularTagsDataDecoder =
    (field "data"
        (succeed PopularTagsData
            |: (field "popularity" (list popularTagDecoder))
            |: (oneOf [ (field "values" (dict valueDecoder)), succeed Dict.empty ])
        )
    )


propertyDecoder : Decoder Property
propertyDecoder =
    succeed Property
        |: oneOf [ (field "ballotId" string), succeed "" ]
        |: (field "createdAt" string)
        |: oneOf [ (field "deleted" bool), succeed False ]
        |: (field "id" string)
        |: (field "keyId" string)
        |: (field "objectId" string)
        |: oneOf [ (field "properties" (dict string)), succeed Dict.empty ]
        |: oneOf [ (field "rating" int), succeed 0 ]
        |: oneOf [ (field "ratingCount" int), succeed 0 ]
        |: oneOf [ (field "ratingSum" int), succeed 0 ]
        |: oneOf [ (field "references" (dict (list string))), succeed Dict.empty ]
        |: oneOf [ (field "subTypeIds" (list string)), succeed [] ]
        |: oneOf [ (field "tags" (list (dict string))), succeed [] ]
        |: (field "type" string)
        |: (field "valueId" string)


userBodyDecoder : Decoder UserBody
userBodyDecoder =
    succeed UserBody
        |: (field "data" userDecoder)


userDecoder : Decoder User
userDecoder =
    succeed User
        |: (field "activated" bool)
        |: oneOf [ (field "apiKey" string), succeed "" ]
        |: oneOf [ (field "email" string), succeed "" ]
        |: (field "name" string)
        |: (field "urlName" string)


userForPortDecoder : Decoder User
userForPortDecoder =
    succeed User
        -- Workaround a bug in ports that removes boolean values.
        |:
            ((field "activated" string)
                |> andThen
                    (\activated ->
                        succeed (not (String.isEmpty activated))
                    )
            )
        |: (field "apiKey" string)
        |: (field "email" string)
        |: (field "name" string)
        |: (field "urlName" string)


valueDecoder : Decoder Types.TypedValue
valueDecoder =
    map5 (,,,,)
        (field "createdAt" string)
        (field "id" string)
        (field "schemaId" string)
        (field "type" string)
        (oneOf [ (field "widgetId" string), succeed "" ])
        |> andThen
            (\( createdAt, id, schemaId, type_, widgetId ) ->
                (field "value" (valueTypeDecoder schemaId widgetId))
                    |> map (\value -> Types.TypedValue createdAt id schemaId type_ value widgetId)
            )


valueTypeDecoder : String -> String -> Decoder ValueType
valueTypeDecoder schemaId widgetId =
    let
        decoder =
            case ( schemaId, widgetId ) of
                ( "schema:bijective-card-reference", _ ) ->
                    bijectiveCardReferenceDecoder |> map BijectiveCardReferenceValue

                ( "schema:boolean", _ ) ->
                    bool |> map BooleanValue

                ( "schema:card-id", _ ) ->
                    string |> map CardIdValue

                ( "schema:card-ids-array", _ ) ->
                    list string |> map CardIdArrayValue

                ( "schema:localized-string", _ ) ->
                    dict string |> map LocalizedStringValue

                ( "schema:number", _ ) ->
                    float |> map NumberValue

                ( "schema:string", _ ) ->
                    string |> map StringValue

                ( "schema:uri", "widget:image" ) ->
                    string |> map ImagePathValue

                ( "schema:uri", _ ) ->
                    string |> map StringValue

                ( "schema:value-ids-array", _ ) ->
                    list string |> map ValueIdArrayValue

                ( _, _ ) ->
                    fail ("TODO Unsupported schemaId \"" ++ schemaId ++ "\" & widgetId \"" ++ widgetId ++ "\"")
    in
        oneOf
            [ decoder
            , value
                |> map
                    (\value ->
                        let
                            str =
                                toString value

                            -- _ =
                            --     Debug.log ("WrongValue \"" ++ str ++ "\", schemaId: " ++ schemaId)
                        in
                            WrongValue str schemaId
                    )
            ]



-- decodeArgumentType : Decoder ArgumentType
-- decodeArgumentType =
--     customDecoder string
--         (\argumentType ->
--             case argumentType of
--                 "because" ->
--                     Ok Because
--                 "but" ->
--                     Ok But
--                 "comment" ->
--                     Ok Comment
--                 "example" ->
--                     Ok Example
--                 _ ->
--                     Err ("Unkown argument type: " ++ argumentType)
--         )
-- decodeStatement : Decoder Statement
-- decodeStatement =
--     succeed Statement
--         |: maybe ("ballotId" := string)
--         |: ("createdAt" := string)
--         |: (("type" := string) |> andThen decodeStatementFromType)
--         |: oneOf [ ("deleted" := bool), succeed False ]
--         |: oneOf [ ("groundIds" := list string), succeed [] ]
--         |: ("id" := string)
--         |: oneOf [ ("isAbuse" := bool), succeed False ]
--         |: oneOf [ ("ratingCount" := int), succeed 0 ]
--         |: oneOf [ ("ratingSum" := int), succeed 0 ]
-- decodeStatementAutocompletion : Decoder StatementAutocompletion
-- decodeStatementAutocompletion =
--     succeed StatementAutocompletion
--         |: ("autocomplete" := string)
--         |: ("distance" := float)
--         |: ("statement" := decodeStatement)
-- decodeStatementFromType : String -> Decoder StatementCustom
-- decodeStatementFromType statementType =
--     case statementType of
--         "Abuse" ->
--             succeed Abuse
--                 |: ("statementId" := string)
--                 |> andThen (\abuse -> succeed (AbuseCustom abuse))
--         "Argument" ->
--             succeed Argument
--                 |: ("argumentType" := decodeArgumentType)
--                 |: ("claimId" := string)
--                 |: ("groundId" := string)
--                 |> andThen (\argument -> succeed (ArgumentCustom argument))
--         "Citation" ->
--             succeed Citation
--                 |: ("citedId" := string)
--                 |: ("eventId" := string)
--                 |: ("personId" := string)
--                 |> andThen (\citation -> succeed (CitationCustom citation))
--         "Event" ->
--             succeed Event
--                 |: ("name" := string)
--                 |> andThen (\event -> succeed (EventCustom event))
--         "Person" ->
--             succeed Person
--                 |: ("name" := string)
--                 |: ("twitterName" := string)
--                 |> andThen (\person -> succeed (PersonCustom person))
--         "PlainStatement" ->
--             succeed Plain
--                 |: ("languageCode" := string)
--                 |: ("name" := string)
--                 |> andThen (\plain -> succeed (PlainCustom plain))
--         "Tag" ->
--             succeed Tag
--                 |: ("name" := string)
--                 |: ("statementId" := string)
--                 |> andThen (\tag -> succeed (TagCustom tag))
--         _ ->
--             fail ("Unkown statement type: " ++ statementType)
-- decodeStatementsAutocompletionBody : Decoder StatementsAutocompletionBody
-- decodeStatementsAutocompletionBody =
--     succeed StatementsAutocompletionBody
--         |: ("data" := list decodeStatementAutocompletion)
