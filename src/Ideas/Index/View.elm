module Ideas.Index.View exposing (..)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import I18n
import Ideas.Index.Types exposing (..)
import Interventions.New.View
import Statements.Lines exposing (viewStatementIdRatedListGroupLine)


view : Model -> Html Msg
view model =
    let
        data =
            model.data

        embed =
            model.embed

        language =
            model.language

        navigateMsg =
            ForParent << Navigate
    in
        case model.discussionProperties of
            Just discussionProperties ->
                div []
                    [ div []
                        [ if Array.isEmpty discussionProperties then
                            p [] [ text <| I18n.translate language I18n.MissingIdeas ]
                          else
                            div [ class "list-group" ]
                                (Array.toList discussionProperties
                                    |> List.map
                                        (\discussionProperty ->
                                            let
                                                classList =
                                                    case discussionProperty.keyId of
                                                        "con" ->
                                                            [ ( "list-group-item-warning", True ) ]

                                                        "pro" ->
                                                            [ ( "list-group-item-success", True ) ]

                                                        _ ->
                                                            [ ( "list-group-item-secondary", True ) ]
                                            in
                                                viewStatementIdRatedListGroupLine
                                                    embed
                                                    language
                                                    navigateMsg
                                                    ""
                                                    classList
                                                    False
                                                    data
                                                    discussionProperty.id
                                        )
                                )
                        ]
                    , hr [] []
                    , Interventions.New.View.view model.newInterventionModel
                        |> Html.map translateNewInterventionMsg
                    ]

            Nothing ->
                text ""
