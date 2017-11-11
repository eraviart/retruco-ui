module Discussions.Item.View exposing (..)

import Array
import Dict
import Discussions.Item.Types exposing (..)
import Discussions.NewIntervention.View
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Http.Error
import I18n
import Statements.Lines exposing (viewStatementIdRatedListGroupLine)
import Views


view : Model -> Html Msg
view model =
    let
        data =
            model.data

        language =
            model.language

        navigateMsg =
            ForParent << Navigate
    in
        case model.discussionPropertyIds of
            Just discussionPropertyIds ->
                div []
                    [ div []
                        [ if Array.isEmpty discussionPropertyIds then
                            p [] [ text <| I18n.translate language I18n.MissingArguments ]
                          else
                            div [ class "list-group" ]
                                (Array.toList discussionPropertyIds
                                    |> List.map
                                        (\discussionPropertyId ->
                                            let
                                                classList =
                                                    case Dict.get discussionPropertyId data.properties of
                                                        Just discussionProperty ->
                                                            case discussionProperty.keyId of
                                                                "con" ->
                                                                    [ ( "list-group-item-warning", True ) ]

                                                                "pro" ->
                                                                    [ ( "list-group-item-success", True ) ]

                                                                _ ->
                                                                    [ ( "list-group-item-secondary", True ) ]

                                                        Nothing ->
                                                            []
                                            in
                                                viewStatementIdRatedListGroupLine
                                                    language
                                                    navigateMsg
                                                    ""
                                                    classList
                                                    False
                                                    data
                                                    discussionPropertyId
                                        )
                                )
                        ]
                    , hr [] []
                    , Discussions.NewIntervention.View.view model.newInterventionModel
                        |> Html.map translateNewInterventionMsg
                    ]

            Nothing ->
                case model.httpError of
                    Just httpError ->
                        div
                            [ class "alert alert-danger"
                            , role "alert"
                            ]
                            [ strong []
                                [ text <|
                                    I18n.translate language I18n.ArgumentsRetrievalFailed
                                        ++ I18n.translate language I18n.Colon
                                ]
                            , text <| Http.Error.toString language httpError
                            ]

                    Nothing ->
                        div [ class "text-center" ]
                            [ Views.viewLoading language ]
