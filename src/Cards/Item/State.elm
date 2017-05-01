module Cards.Item.State exposing (..)

import Authenticator.Types exposing (Authentication)
import Cards.Item.Routes exposing (..)
import Cards.Item.Types exposing (..)
import Http
import I18n
import Navigation
import Ports
import Properties.KeysAutocomplete.State
import Requests
import SameKeyProperties.State
import Task
import Types exposing (..)
import Urls


init : Model
init =
    { authentication = Nothing
    , data = initData
    , httpError = Nothing
    , id = ""
    , keysAutocompleteModel = Properties.KeysAutocomplete.State.init [] True
    , language = I18n.English
    , sameKeyPropertiesModel = Nothing
    }


mergeModelData : DataProxy a -> Model -> Model
mergeModelData data model =
    let
        mergedData =
            mergeData data model.data
    in
        { model
            | data = mergedData
            , sameKeyPropertiesModel =
                case model.sameKeyPropertiesModel of
                    Just sameKeyPropertiesModel ->
                        Just <| SameKeyProperties.State.mergeModelData mergedData sameKeyPropertiesModel

                    Nothing ->
                        Nothing
        }


subscriptions : Model -> Sub InternalMsg
subscriptions model =
    List.filterMap identity
        [ Just <|
            Sub.map KeysAutocompleteMsg (Properties.KeysAutocomplete.State.subscriptions model.keysAutocompleteModel)
        , case model.sameKeyPropertiesModel of
            Just sameKeyPropertiesModel ->
                Just <| Sub.map SameKeyPropertiesMsg (SameKeyProperties.State.subscriptions sameKeyPropertiesModel)

            Nothing ->
                Nothing
        ]
        |> Sub.batch


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddKey typedValue ->
            -- TODO
            -- update (LoadProperties typedValue.id) model
            ( model, Cmd.none )

        CreateKey keyName ->
            case model.authentication of
                Just _ ->
                    ( model
                    , Requests.postValue
                        model.authentication
                        (LocalizedInputTextField (I18n.iso639_1FromLanguage model.language) keyName)
                        |> Http.send (ForSelf << KeyUpserted)
                    )

                Nothing ->
                    ( model
                    , Task.perform
                        (\_ -> ForParent <| RequireSignIn <| CreateKey keyName)
                        (Task.succeed ())
                    )

        KeysAutocompleteMsg childMsg ->
            let
                ( keysAutocompleteModel, childCmd ) =
                    Properties.KeysAutocomplete.State.update
                        childMsg
                        model.authentication
                        model.language
                        "keyId"
                        model.keysAutocompleteModel
            in
                ( { model | keysAutocompleteModel = keysAutocompleteModel }
                , Cmd.map translateKeysAutocompleteMsg childCmd
                )

        KeyUpserted (Err httpError) ->
            ( { model | httpError = Just httpError }, Cmd.none )

        KeyUpserted (Ok { data }) ->
            -- let
            --     mergedModel =
            --          mergeModelData data model
            -- in
            --     update (LoadProperties data.id) mergedModel
            ( model, Cmd.none )

        Retrieve ->
            ( { model | httpError = Nothing }
            , Requests.getCard model.authentication model.id
                |> Http.send (ForSelf << Retrieved)
            )

        Retrieved (Err httpError) ->
            ( { model
                | httpError = Just httpError
                , keysAutocompleteModel = Properties.KeysAutocomplete.State.init [] True
              }
            , Cmd.none
            )

        Retrieved (Ok { data }) ->
            let
                mergedModel =
                    mergeModelData data model

                card =
                    getCard data.cards data.id

                language =
                    model.language
            in
                ( { mergedModel
                    | keysAutocompleteModel = Properties.KeysAutocomplete.State.init card.subTypeIds True
                  }
                , -- TODO
                  Ports.setDocumentMetadata
                    { description = I18n.translate language I18n.CardsDescription
                    , imageUrl = Urls.appLogoFullUrl
                    , title = I18n.translate language I18n.Cards
                    }
                )

        SameKeyPropertiesMsg childMsg ->
            case model.sameKeyPropertiesModel of
                Just sameKeyPropertiesModel ->
                    let
                        ( updatedSameKeyPropertiesModel, childCmd ) =
                            SameKeyProperties.State.update childMsg sameKeyPropertiesModel
                    in
                        ( { model | sameKeyPropertiesModel = Just updatedSameKeyPropertiesModel }
                        , Cmd.map translateSameKeyPropertiesMsg childCmd
                        )

                Nothing ->
                    ( model, Cmd.none )


urlUpdate :
    Maybe Authentication
    -> I18n.Language
    -> Navigation.Location
    -> String
    -> Route
    -> Model
    -> ( Model, Cmd Msg )
urlUpdate authentication language location id route model =
    let
        ( updatedModel, updatedCmd ) =
            update Retrieve
                { init
                    | authentication = authentication
                    , id = id
                    , language = language
                }
    in
        case route of
            IndexRoute ->
                ( { updatedModel | sameKeyPropertiesModel = Nothing }, updatedCmd )

            SameKeyPropertiesRoute keyId ->
                let
                    sameKeyPropertiesModel =
                        SameKeyProperties.State.init authentication language id keyId

                    ( updatedSameKeyPropertiesModel, updatedSameKeyPropertiesCmd ) =
                        SameKeyProperties.State.urlUpdate location sameKeyPropertiesModel
                in
                    { updatedModel | sameKeyPropertiesModel = Just updatedSameKeyPropertiesModel }
                        ! [ updatedCmd
                          , Cmd.map translateSameKeyPropertiesMsg updatedSameKeyPropertiesCmd
                          ]
