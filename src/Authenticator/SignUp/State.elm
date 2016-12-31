module Authenticator.SignUp.State exposing (..)

import Authenticator.SignUp.Types exposing (..)
import Configuration exposing (apiUrl)
import Decoders
import Dict exposing (Dict)
import Http
import Json.Encode
import Task


init : Model
init =
    { email = ""
    , errors = Dict.empty
    , httpError = Nothing
    , password = ""
    , username = ""
    }


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Cancel ->
            ( { model | httpError = Nothing }
            , Task.perform (\_ -> ForParent (Terminated (Err ()))) (Task.succeed ())
            )

        EmailInput text ->
            ( { model | email = text }, Cmd.none )

        PasswordInput text ->
            ( { model | password = text }, Cmd.none )

        Submit ->
            let
                errorsList =
                    (List.filterMap
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
                        , ( "password"
                          , if String.isEmpty model.password then
                                Just "Missing password"
                            else
                                Nothing
                          )
                        , ( "username"
                          , if String.isEmpty model.username then
                                Just "Missing username"
                            else
                                Nothing
                          )
                        ]
                    )

                cmd =
                    if List.isEmpty errorsList then
                        let
                            bodyJson =
                                Json.Encode.object
                                    [ ( "email", Json.Encode.string model.email )
                                    , ( "name", Json.Encode.string model.username )
                                    , ( "urlName", Json.Encode.string model.username )
                                    , ( "password", Json.Encode.string model.password )
                                    ]
                        in
                            Http.post
                                (apiUrl ++ "users")
                                (Http.stringBody "application/json" <| Json.Encode.encode 2 bodyJson)
                                Decoders.userBodyDecoder
                                |> Http.send (ForSelf << UserCreated)
                    else
                        Cmd.none
            in
                ( { model | errors = Dict.fromList errorsList }, cmd )

        UserCreated (Err httpError) ->
            ( { model | httpError = Just httpError }, Cmd.none )

        UserCreated (Ok body) ->
            ( { model | httpError = Nothing }
            , Task.perform (\_ -> ForParent (Terminated (Ok <| Just body.data))) (Task.succeed ())
            )

        UsernameInput text ->
            ( { model | username = text }, Cmd.none )
