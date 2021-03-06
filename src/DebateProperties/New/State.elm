module DebateProperties.New.State exposing (..)

import Authenticator.Types exposing (Authentication)
import Constants exposing (debateKeyIds)
import Data exposing (initDataWithId, mergeData)
import DebateProperties.New.Types exposing (..)
import Dict exposing (Dict)
import Http
import I18n
import Navigation
import Ports
import Requests
import Task
import Types exposing (DataProxy)
import Urls
import Values.New.State
import Values.New.Types


convertControls : Model -> Model
convertControls model =
    let
        keyIdError =
            if List.member model.keyId debateKeyIds then
                Nothing
            else if model.keyId == "" then
                Just I18n.MissingValue
            else
                Just I18n.UnknownValue
    in
        { model
            | errors =
                case keyIdError of
                    Just keyIdError ->
                        Dict.singleton "keyId" keyIdError

                    Nothing ->
                        Dict.empty
        }


init : Maybe Authentication -> Bool -> I18n.Language -> String -> List String -> Model
init authentication embed language objectId validFieldTypes =
    { authentication = authentication
    , data = initDataWithId
    , embed = embed
    , errors = Dict.empty
    , httpError = Nothing
    , keyId = ""
    , language = language
    , newValueModel = Values.New.State.init authentication embed language validFieldTypes
    , objectId = objectId
    , validFieldTypes = validFieldTypes
    }


mergeModelData : DataProxy a -> Model -> Model
mergeModelData data model =
    { model
        | data = mergeData data model.data
    }


propagateModelDataChange : Model -> Model
propagateModelDataChange model =
    { model
        | newValueModel =
            Values.New.State.mergeModelData model.data model.newValueModel
                |> Values.New.State.propagateModelDataChange
    }


setContext : Maybe Authentication -> Bool -> I18n.Language -> Model -> Model
setContext authentication embed language model =
    { model
        | authentication = authentication
        , embed = embed
        , language = language
        , newValueModel = Values.New.State.setContext authentication embed language model.newValueModel
    }


subscriptions : Model -> Sub InternalMsg
subscriptions model =
    Sub.map NewValueMsg (Values.New.State.subscriptions model.newValueModel)


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyIdChanged keyId ->
            ( convertControls { model | keyId = keyId }, Cmd.none )

        NewValueMsg childMsg ->
            let
                ( newValueModel, childCmd ) =
                    model.newValueModel
                        |> Values.New.State.setContext model.authentication model.embed model.language
                        |> Values.New.State.update childMsg
            in
                ( { model | newValueModel = newValueModel }
                , Cmd.map translateNewValueMsg childCmd
                )

        Submit ->
            let
                newModel =
                    convertControls model
            in
                if Dict.isEmpty newModel.errors then
                    update (NewValueMsg Values.New.Types.Submit) newModel
                else
                    ( newModel, Cmd.none )

        Upserted (Err httpError) ->
            ( { model | httpError = Just httpError }, Cmd.none )

        Upserted (Ok body) ->
            let
                data =
                    mergeData body.data model.data
            in
                ( { model | data = { data | id = body.data.id } }
                , Task.perform (\_ -> ForParent <| PropertyUpserted data) (Task.succeed ())
                )

        ValueRated (Err httpError) ->
            ( { model | httpError = Just httpError }, Cmd.none )

        ValueRated (Ok body) ->
            let
                mergedModel =
                    mergeModelData body.data model
                        |> propagateModelDataChange

                ballot =
                    Dict.get body.data.id mergedModel.data.ballots
            in
                case ballot of
                    Just ballot ->
                        let
                            mergedData =
                                mergedModel.data

                            data =
                                { mergedData | id = ballot.statementId }
                        in
                            ( { mergedModel | data = data }
                            , Requests.postProperty model.authentication model.objectId model.keyId data.id (Just 1)
                                |> Http.send (ForSelf << Upserted)
                            )

                    Nothing ->
                        ( mergedModel, Cmd.none )

        ValueUpserted data ->
            ( { model | data = mergeData data model.data }
            , Requests.rateStatement model.authentication data.id 1
                |> Http.send (ForSelf << ValueRated)
            )


urlUpdate : Navigation.Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    let
        language =
            model.language
    in
        ( model
        , Ports.setDocumentMetadata
            { description = I18n.translate language I18n.NewArgumentDescription
            , imageUrl = Urls.appLogoFullUrl
            , title = I18n.translate language I18n.NewArgument
            }
        )
