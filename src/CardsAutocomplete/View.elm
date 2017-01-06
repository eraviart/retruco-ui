module CardsAutocomplete.View exposing (..)

import Autocomplete
import CardsAutocomplete.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)
import I18n
import Json.Decode
import Types exposing (CardAutocompletion)
import Views exposing (errorInfos)


viewAutocomplete : I18n.Language -> String -> Maybe I18n.TranslationId -> Model -> Html Msg
viewAutocomplete language parentId error model =
    let
        controlId =
            if String.isEmpty parentId then
                "autocomplete"
            else
                parentId ++ ".autocomplete"

        controlFindAnother =
            I18n.translate language I18n.FindAnotherCard

        controlFindOne =
            I18n.translate language I18n.FindCard

        controlLabel =
            I18n.translate language I18n.Card

        controlPlaceholder =
            I18n.translate language I18n.CardPlaceholder

        controlSelectOneOrTypeMoreCharacters =
            I18n.translate language I18n.SelectCardOrTypeMoreCharacters

        controlTitle =
            I18n.translate language I18n.EnterCard

        ( errorClass, errorAttributes, errorBlock ) =
            errorInfos language controlId error

        decodeKeyCode =
            keyCode
                |> Json.Decode.andThen
                    (\code ->
                        if code == 38 || code == 40 then
                            Json.Decode.succeed (ForSelf NoOp)
                        else if code == 27 then
                            Json.Decode.succeed (ForSelf HandleEscape)
                        else
                            Json.Decode.fail "not handling that key"
                    )

        menuId =
            controlId ++ "-menu"

        query =
            case model.selected of
                Just selected ->
                    selected.autocomplete

                Nothing ->
                    model.autocomplete

        showAutocompleteMenu =
            case model.autocompleteMenuState of
                AutocompleteMenuVisible ->
                    True

                _ ->
                    False

        menu =
            if showAutocompleteMenu then
                [ Html.map (ForSelf << AutocompleteMsg)
                    (Autocomplete.view
                        { getItemId = .card >> .id
                        , menuId = menuId
                        , viewItemContent = viewAutocompleteItemContent
                        }
                        autocompleterSize
                        model.autocompleter
                        model.autocompletions
                    )
                ]
            else
                []
    in
        div [ class ("form-group" ++ errorClass) ]
            (List.concat
                [ [ label [ class "control-label", for controlId ] [ text controlLabel ]
                  , div [ class "input-group" ]
                        [ input
                            (List.concat
                                [ [ attribute "aria-autocomplete" "list"
                                  , ariaExpanded <| String.toLower <| toString showAutocompleteMenu
                                  , attribute "aria-haspopup" <| String.toLower <| toString showAutocompleteMenu
                                  , attribute "aria-owns" menuId
                                  , autocomplete False
                                  , class "form-control"
                                  , id controlId
                                  , onFocus (ForSelf Focus)
                                  , onInput (ForSelf << InputChanged)
                                  , onWithOptions
                                        "keydown"
                                        { preventDefault = True, stopPropagation = False }
                                        decodeKeyCode
                                  , placeholder controlPlaceholder
                                  , title controlTitle
                                  , role "combobox"
                                  , type_ "text"
                                  , value query
                                  ]
                                , (case model.selected of
                                    Just selected ->
                                        [ ariaActiveDescendant selected.autocomplete ]

                                    Nothing ->
                                        []
                                  )
                                , errorAttributes
                                ]
                            )
                            []
                        , span [ class "input-group-btn" ]
                            [ (case model.autocompleteMenuState of
                                AutocompleteMenuHidden ->
                                    button
                                        [ class "btn btn-secondary"
                                        , onWithOptions "click"
                                            { preventDefault = True, stopPropagation = False }
                                            (Json.Decode.succeed (ForSelf MouseOpen))
                                        ]
                                        (case model.selected of
                                            Just selected ->
                                                [ span
                                                    [ ariaHidden True
                                                    , class "text-success fa fa-check fa-fw"
                                                    ]
                                                    []
                                                , span
                                                    [ class "sr-only" ]
                                                    [ text controlFindAnother ]
                                                ]

                                            Nothing ->
                                                [ span
                                                    [ ariaHidden True
                                                    , class "fa fa-caret-down fa-fw"
                                                    ]
                                                    []
                                                , span
                                                    [ class "sr-only" ]
                                                    [ text controlFindOne ]
                                                ]
                                        )

                                AutocompleteMenuVisible ->
                                    button
                                        [ class "active btn btn-secondary"
                                        , onWithOptions "click"
                                            { preventDefault = True, stopPropagation = False }
                                            (Json.Decode.succeed (ForSelf MouseClose))
                                        ]
                                        [ span
                                            [ ariaHidden True
                                            , class "fa fa-caret-down fa-fw"
                                            ]
                                            []
                                        , span
                                            [ class "sr-only" ]
                                            [ text "Select a person or type more characters" ]
                                        ]

                                _ ->
                                    button
                                        [ class "btn btn-secondary"
                                        , disabled True
                                        , onWithOptions "click"
                                            { preventDefault = True, stopPropagation = False }
                                            (Json.Decode.succeed (ForSelf NoOp))
                                        ]
                                        [ span [ ariaHidden True, class "fa fa-fw fa-refresh fa-spin" ] []
                                        , span [ class "sr-only" ] [ text <| I18n.translate language I18n.LoadingMenu ]
                                        ]
                              )
                            ]
                        , span [ class "input-group-btn" ]
                            [ button [ class "btn btn-secondary" ]
                                [ text <| I18n.translate language I18n.New ]
                            ]
                        ]
                  , span [ class "sr-only" ] [ text <| I18n.translate language I18n.LoadingMenu ]
                  ]
                , menu
                , errorBlock
                ]
            )


viewAutocompleteFieldset : I18n.Language -> String -> String -> Maybe I18n.TranslationId -> Model -> Html Msg
viewAutocompleteFieldset language fieldLabel fieldId error model =
    let
        prefix =
            if String.isEmpty fieldId then
                fieldId
            else
                fieldId ++ "."
    in
        fieldset [ class "form-group" ]
            [ legend [] [ text fieldLabel ]
            , viewAutocomplete language fieldId error model
            ]


viewAutocompleteItemContent : CardAutocompletion -> List (Html Never)
viewAutocompleteItemContent cardAutocompletion =
    [ Html.text cardAutocompletion.autocomplete ]
