module Statements.ViewsHelpers exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onClick)
import Html.Helpers exposing (aForPath)
import I18n
import Types exposing (Argument, DataProxy)
import Urls
import Values.ViewsHelpers


keyIdLabelCouples : List ( String, I18n.TranslationId )
keyIdLabelCouples =
    [ ( "pros", I18n.DebateArgumentFor )
    , ( "cons", I18n.DebateArgumentAgainst )
    ]


viewArgumentsBlock : I18n.Language -> (String -> msg) -> DataProxy a -> String -> String -> List Argument -> Html msg
viewArgumentsBlock language navigateMsg data objectsUrlName objectId arguments =
    let
        viewArgument argument =
            li [ class "list-group-item justify-content-between" ]
                [ div [ class "d-inline-flex" ]
                    [ span
                        [ ariaHidden True
                        , class
                            ("fa "
                                ++ (if argument.keyId == "cons" then
                                        "fa-minus"
                                    else if argument.keyId == "pros" then
                                        "fa-plus"
                                    else
                                        "fa-circle"
                                   )
                                ++ " fa-fw mr-2"
                            )
                        ]
                        []
                    , Values.ViewsHelpers.viewValueIdLine
                        language
                        (Just navigateMsg)
                        data
                        False
                        argument.valueId
                    ]
                , aForPath
                    navigateMsg
                    language
                    ((Urls.objectIdPath argument.valueId data) ++ "/arguments")
                    [ class "btn btn-secondary" ]
                    [ text (I18n.translate language (I18n.Debate)) ]
                ]
    in
        div []
            [ h2 [ class "d-flex justify-content-between" ]
                [ span [] [ text <| I18n.translate language I18n.Arguments ]
                , aForPath
                    navigateMsg
                    language
                    ("/" ++ objectsUrlName ++ "/" ++ objectId ++ "/arguments")
                    [ class "btn btn-secondary" ]
                    [ text (I18n.translate language (I18n.Debate)) ]
                ]
            , ul [ class "list-group" ]
                (arguments
                    |> List.map viewArgument
                )
            ]


viewDebatePropertiesBlock :
    I18n.Language
    -> (String -> msg)
    -> DataProxy a
    -> List String
    -> Html msg
viewDebatePropertiesBlock language navigateMsg data propertyIds =
    div []
        [ h2 [] [ text <| I18n.translate language I18n.Arguments ]
        , if List.isEmpty propertyIds then
            p [] [ text <| I18n.translate language I18n.MissingArguments ]
          else
            ul [ class "list-group" ]
                (List.filterMap
                    (\propertyId ->
                        case Dict.get propertyId data.properties of
                            Just property ->
                                let
                                    ballot =
                                        Dict.get property.ballotId data.ballots

                                    ballotRating =
                                        Maybe.map .rating ballot

                                    keyLabel =
                                        Dict.get property.keyId (Dict.fromList keyIdLabelCouples)
                                            |> Maybe.map (I18n.translate language)
                                            |> Maybe.withDefault property.keyId
                                in
                                    Just <|
                                        li [ class "d-flex flex-nowrap justify-content-between list-group-item" ]
                                            [ div [ class "align-items-baseline d-flex flex-nowrap" ]
                                                [ span
                                                    [ ariaHidden True
                                                    , classList
                                                        [ ( "fa", True )
                                                        , ( if property.keyId == "cons" then
                                                                "fa-minus"
                                                            else if property.keyId == "pros" then
                                                                "fa-plus"
                                                            else
                                                                "fa-info"
                                                          , True
                                                          )
                                                        , ( "mr-2", True )
                                                        ]
                                                    ]
                                                    []
                                                , div []
                                                    [ h4 [] [ text keyLabel ]
                                                    , Values.ViewsHelpers.viewValueIdLine
                                                        language
                                                        (Just navigateMsg)
                                                        data
                                                        False
                                                        property.valueId
                                                    ]
                                                ]
                                            , viewRatingPanel
                                                language
                                                navigateMsg
                                                (Just "arguments")
                                                property
                                            ]

                            Nothing ->
                                Nothing
                    )
                    propertyIds
                )
        ]


viewRatingPanel :
    I18n.Language
    -> (String -> msg)
    -> Maybe String
    -> { a | arguments : List Argument, id : String, ratingCount : Int, ratingSum : Int, trashed : Bool }
    -> Html msg
viewRatingPanel language navigateMsg objectsUrlName { arguments, id, ratingCount, ratingSum, trashed } =
    let
        buttonClass =
            classList
                [ ( "btn", True )
                , ( "btn-lg", True )
                , ( if trashed then
                        "btn-danger"
                    else if ratingSum > 0 then
                        "btn-outline-success"
                    else
                        "btn-outline-danger"
                  , True
                  )
                ]

        buttonWithAttributes =
            case objectsUrlName of
                Just objectsUrlName ->
                    aForPath
                        navigateMsg
                        language
                        ("/" ++ objectsUrlName ++ "/" ++ id)
                        [ buttonClass ]

                Nothing ->
                    button
                        [ buttonClass
                        , disabled True
                        , type_ "button"
                        ]
    in
        buttonWithAttributes
            [ strong [] [ text <| toString ratingSum ]
            , text " / "
            , text <|
                I18n.translate
                    language
                    (I18n.CountVotes ratingCount)
            , br [] []
            , text <|
                I18n.translate
                    language
                    (I18n.CountArguments <| List.length arguments)
            ]


viewRatingToolbar :
    I18n.Language
    -> DataProxy a
    -> (String -> Maybe Int -> msg)
    -> (String -> msg)
    -> { b | ballotId : String, id : String }
    -> Html msg
viewRatingToolbar language data rateMsg trashMsg { ballotId, id } =
    div
        [ class "toolbar"
        , role "toolbar"
        ]
        [ let
            ballot =
                Dict.get ballotId data.ballots

            ballotRating =
                Maybe.map .rating ballot
          in
            div
                [ ariaLabel "Rating panel"
                , class "btn-group"
                , role "group"
                ]
                [ button
                    [ ariaPressed (ballotRating == Just 1)
                    , classList
                        [ ( "active", ballotRating == Just 1 )
                        , ( "btn", True )
                        , ( "btn-outline-success", True )
                        ]
                    , onClick
                        (if ballotRating == Just 1 then
                            rateMsg id Nothing
                         else
                            rateMsg id (Just 1)
                        )
                    , type_ "button"
                    ]
                    [ span
                        [ ariaHidden True
                        , class "fa fa-thumbs-o-up"
                        ]
                        []
                    , text " "
                    , text <|
                        I18n.translate
                            language
                            I18n.Agree
                    ]
                , button
                    [ ariaPressed (ballotRating == Just 0)
                    , classList
                        [ ( "active", ballotRating == Just 0 )
                        , ( "btn", True )
                        , ( "btn-outline-secondary", True )
                        ]
                    , onClick
                        (if ballotRating == Just 0 then
                            rateMsg id Nothing
                         else
                            rateMsg id (Just 0)
                        )
                    , type_ "button"
                    ]
                    [ span
                        [ ariaHidden True
                        , class "fa fa-square-o"
                        ]
                        []
                    , text " "
                    , text <|
                        I18n.translate
                            language
                            I18n.Abstain
                    ]
                , button
                    [ ariaPressed (ballotRating == Just -1)
                    , classList
                        [ ( "active", ballotRating == Just -1 )
                        , ( "btn", True )
                        , ( "btn-outline-danger", True )
                        ]
                    , onClick
                        (if ballotRating == Just -1 then
                            rateMsg id Nothing
                         else
                            rateMsg id (Just -1)
                        )
                    , type_ "button"
                    ]
                    [ span
                        [ ariaHidden True
                        , class "fa fa-thumbs-o-down"
                        ]
                        []
                    , text " "
                    , text <|
                        I18n.translate
                            language
                            I18n.Disagree
                    ]
                ]
        , text " "
        , button
            [ classList
                [ ( "btn", True )
                , ( "btn-danger", True )
                ]
            , onClick (trashMsg id)
            , type_ "button"
            ]
            [ span
                [ ariaHidden True
                , class "fa fa-trash-o"
                ]
                []
            , text " "
            , text <|
                I18n.translate
                    language
                    I18n.Trash
            ]
        ]
