module Authenticator.ViewsHelpers exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)
import I18n
import Json.Decode


errorInfos : String -> Maybe String -> ( String, List (Attribute msg), List (Html msg1) )
errorInfos controlId error =
    let
        errorId =
            controlId ++ "-error"
    in
        case error of
            Just error ->
                ( " has-danger"
                , [ ariaDescribedby errorId ]
                , [ div
                        [ class "form-control-feedback"
                        , id errorId
                        ]
                        [ text error ]
                  ]
                )

            Nothing ->
                ( "", [], [] )


viewConnectionTabs : I18n.Language -> Maybe msg -> Maybe msg -> Maybe msg -> Html msg
viewConnectionTabs language passwordResetMsg signInMsg signUpMsg =
    ul [ class "nav nav-tabs" ]
        [ li [ class "nav-item" ]
            [ a
                ([ classList
                    [ ( "active", signInMsg == Nothing )
                    , ( "nav-link", True )
                    ]
                 , href "#"
                 ]
                    ++ case signInMsg of
                        Just signInMsg ->
                            [ onWithOptions
                                "click"
                                { stopPropagation = True, preventDefault = True }
                                (Json.Decode.succeed signInMsg)
                            ]

                        Nothing ->
                            []
                )
                [ text <| I18n.translate language I18n.SignInTab ]
            ]
        , li [ class "nav-item" ]
            [ a
                ([ classList
                    [ ( "active", passwordResetMsg == Nothing )
                    , ( "nav-link", True )
                    ]
                 , href "#"
                 ]
                    ++ case passwordResetMsg of
                        Just passwordResetMsg ->
                            [ onWithOptions
                                "click"
                                { stopPropagation = True, preventDefault = True }
                                (Json.Decode.succeed passwordResetMsg)
                            ]

                        Nothing ->
                            []
                )
                [ text <| I18n.translate language I18n.ResetPasswordTab ]
            ]
        , li [ class "nav-item" ]
            [ a
                ([ classList
                    [ ( "active", signUpMsg == Nothing )
                    , ( "nav-link", True )
                    ]
                 , href "#"
                 ]
                    ++ case signUpMsg of
                        Just signUpMsg ->
                            [ onWithOptions
                                "click"
                                { stopPropagation = True, preventDefault = True }
                                (Json.Decode.succeed signUpMsg)
                            ]

                        Nothing ->
                            []
                )
                [ text <| I18n.translate language I18n.SignUpTab ]
            ]
        ]


viewEmailControl : (String -> msg) -> I18n.Language -> Maybe String -> String -> Html msg
viewEmailControl valueChanged language error controlValue =
    let
        controlId =
            "email"

        controlLabel =
            I18n.translate language I18n.Email

        controlPlaceholder =
            I18n.translate language I18n.EmailPlaceholder

        controlTitle =
            I18n.translate language I18n.EnterEmail

        ( errorClass, errorAttributes, errorBlock ) =
            errorInfos controlId error
    in
        div [ class ("form-group" ++ errorClass) ]
            ([ label [ class "control-label", for controlId ] [ text controlLabel ]
             , input
                ([ class "form-control"
                 , id controlId
                 , placeholder controlPlaceholder
                 , required True
                 , title controlTitle
                 , type_ "email"
                 , value controlValue
                 , onInput valueChanged
                 ]
                    ++ errorAttributes
                )
                []
             ]
                ++ errorBlock
            )


viewPasswordControl : (String -> msg) -> I18n.Language -> Maybe String -> String -> Html msg
viewPasswordControl valueChanged language error controlValue =
    let
        controlId =
            "password"

        controlLabel =
            I18n.translate language I18n.Password

        controlPlaceholder =
            I18n.translate language I18n.PasswordPlaceholder

        controlTitle =
            I18n.translate language I18n.EnterPassword

        ( errorClass, errorAttributes, errorBlock ) =
            errorInfos controlId error
    in
        div [ class ("form-group" ++ errorClass) ]
            ([ label [ class "control-label", for controlId ] [ text controlLabel ]
             , input
                ([ class "form-control"
                 , id controlId
                 , placeholder controlPlaceholder
                 , required True
                 , title controlTitle
                 , type_ "password"
                 , value controlValue
                 , onInput valueChanged
                 ]
                    ++ errorAttributes
                )
                []
             ]
                ++ errorBlock
            )


viewUsernameControl : (String -> msg) -> I18n.Language -> Maybe String -> String -> Html msg
viewUsernameControl valueChanged language error controlValue =
    let
        controlId =
            "username"

        controlLabel =
            I18n.translate language I18n.Username

        controlPlaceholder =
            I18n.translate language I18n.UsernamePlaceholder

        controlTitle =
            I18n.translate language I18n.EnterUsername

        ( errorClass, errorAttributes, errorBlock ) =
            errorInfos controlId error
    in
        div [ class ("form-group" ++ errorClass) ]
            ([ label [ class "control-label", for controlId ] [ text controlLabel ]
             , input
                ([ class "form-control"
                 , id controlId
                 , placeholder controlPlaceholder
                 , required True
                 , title controlTitle
                 , type_ "text"
                 , value controlValue
                 , onInput valueChanged
                 ]
                    ++ errorAttributes
                )
                []
             ]
                ++ errorBlock
            )
