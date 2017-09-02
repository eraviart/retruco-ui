module Authenticator.ResetPassword.State exposing (..)

import Authenticator.ResetPassword.Types exposing (..)
import Configuration exposing (apiUrl)
import Decoders
import Dict
import Http
import Json.Encode
import Task


init : Model
init =
    { errors = Dict.empty
    , email = ""
    , httpError = Nothing
    }


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Cancel ->
            ( model
            , Task.perform (\_ -> ForParent (Terminated (Err ()))) (Task.succeed ())
            )

        EmailInput text ->
            ( { model | email = text }, Cmd.none )

        PasswordReset (Err httpError) ->
            ( { model | httpError = Just httpError }, Cmd.none )

        PasswordReset (Ok _) ->
            ( { model | httpError = Nothing }
            , Task.perform (\_ -> ForParent (Terminated (Ok Nothing))) (Task.succeed ())
            )

        Submit ->
            let
                errorsList =
                    List.filterMap
                        (\( name, errorMaybe ) ->
                            case errorMaybe of
                                Just error ->
                                    Just ( name, error )

                                Nothing ->
                                    Nothing
                        )
                        [ ( "email"
                          , if String.isEmpty model.email then
                                Just "Missing email"
                            else
                                Nothing
                          )
                        ]

                cmd =
                    if List.isEmpty errorsList then
                        let
                            bodyJson =
                                Json.Encode.object
                                    [ ( "email", Json.Encode.string model.email )
                                    ]
                        in
                            Http.post
                                (apiUrl ++ "users/reset-password")
                                (Http.stringBody "application/json" <| Json.Encode.encode 2 bodyJson)
                                Decoders.messageBodyDecoder
                                |> Http.send (ForSelf << PasswordReset)
                    else
                        Cmd.none
            in
                ( { model | errors = Dict.fromList errorsList }, cmd )
