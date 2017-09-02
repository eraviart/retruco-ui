module Authenticator.ChangePassword.State exposing (..)

import Authenticator.ChangePassword.Types exposing (..)
import Dict
import Http
import I18n
import Requests
import Task


init : String -> String -> Model
init userId authorization =
    { authorization = authorization
    , errors = Dict.empty
    , httpError = Nothing
    , password = ""
    , userId = userId
    }


update : InternalMsg -> Model -> I18n.Language -> ( Model, Cmd Msg )
update msg model _ =
    case msg of
        Cancel ->
            ( { model | httpError = Nothing }
            , Task.perform (\_ -> ForParent (Terminated (Err ()))) (Task.succeed ())
            )

        PasswordInput text ->
            ( { model | password = text }, Cmd.none )

        PasswordReset (Err httpError) ->
            ( { model | httpError = Just httpError }, Cmd.none )

        PasswordReset (Ok body) ->
            ( { model | httpError = Nothing }
            , Task.perform (\_ -> ForParent (Terminated (Ok <| Just body.data))) (Task.succeed ())
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
                        [ ( "password"
                          , if String.isEmpty model.password then
                                Just "Missing password"
                            else
                                Nothing
                          )
                        ]

                cmd =
                    if List.isEmpty errorsList then
                        Requests.resetPassword model.userId model.authorization model.password
                            |> Http.send (ForSelf << PasswordReset)
                    else
                        Cmd.none
            in
                ( { model | errors = Dict.fromList errorsList }, cmd )
