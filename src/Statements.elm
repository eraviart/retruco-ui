module Statements exposing (init, InternalMsg(Load), load, Model, MsgTranslation, MsgTranslator, translateMsg, update, urlUpdate, view, viewIndex)

import Authenticator.Model
import Dict exposing (Dict)
import Hop.Types
import Html exposing (article, h1, Html, li, text, ul)
import Html.Attributes exposing (class)
import Html.App
import Http
import Navigation
import NewStatement
import Requests exposing (newTaskDeleteStatementRating, newTaskFlagAbuse, newTaskGetStatements, newTaskRateStatement,
    updateFromDataId)
import Routes exposing (makeUrl, StatementsNestedRoute(..))
import Statement
import Task
import Types exposing (Ballot, DataId, DataIdBody, DataIdsBody, decodeDataIdsBody, SearchCriteria, Statement,
    StatementCustom(..))
import Views exposing (aForPath, viewNotFound, viewStatementLine)


-- MODEL


type alias Model =
    { ballotById : Dict String Ballot
    , loaded : Bool
    -- , location : Hop.Types.Location
    , newStatementModel : NewStatement.Model
    , route : StatementsNestedRoute
    , statementModel : Statement.Model
    , statementById : Dict String Statement
    , statementIds : List String
    }


init : Model
init =
    { ballotById = Dict.empty
    , loaded = False
    -- , location = Hop.Types.newLocation
    , newStatementModel = NewStatement.init
    , route = StatementsNotFoundRoute
    , statementModel = Statement.init
    , statementById = Dict.empty
    , statementIds = []
    }


-- ROUTING


urlUpdate : (StatementsNestedRoute, Hop.Types.Location) -> Model -> (Model, Cmd Msg)
urlUpdate (route, location) model =
    let
        model1 = { model
            -- | location = location
            | route = route
            }
    in
        case route of
            StatementRoute statementId ->
                let
                    statementModel = model1.statementModel
                    model2 =
                        { model1
                        | statementModel =
                            { statementModel
                            | statementId = statementId
                            }
                        }
                in
                    (model2, load)

            StatementsIndexRoute ->
                (model1, load)

            StatementsNotFoundRoute ->
                (model1, Cmd.none)


-- UPDATE


type ExternalMsg
    = Navigate String


type InternalMsg
    = Error Http.Error
    | FlagAbuse String
    | FlagAbuseError Http.Error
    | FlaggedAbuse DataIdBody
    | Load
    | Loaded DataIdsBody
    | NewStatementMsg NewStatement.Msg
    | Rated DataIdBody
    | RateError Http.Error
    | RatingChanged (Maybe Int) String
    | StatementMsg Statement.InternalMsg


type Msg
    = ForParent ExternalMsg
    | ForSelf InternalMsg


type alias MsgTranslation parentMsg =
    { onInternalMsg : InternalMsg -> parentMsg
    , onNavigate : String -> parentMsg
    }


type alias MsgTranslator parentMsg = Msg -> parentMsg


load : Cmd Msg
load =
    Task.perform (\_ -> Debug.crash "") (\_ -> ForSelf Load) (Task.succeed "")


navigate : String -> Msg
navigate path =
    ForParent (Navigate path)


statementMsgTranslation : Statement.MsgTranslation Msg
statementMsgTranslation =
    { onInternalMsg = \internalMsg -> ForSelf (StatementMsg internalMsg)
    , onNavigate = \path -> ForParent (Navigate path)
    }


translateStatementMsg : Statement.MsgTranslator Msg
translateStatementMsg = Statement.translateMsg statementMsgTranslation


translateMsg : MsgTranslation parentMsg -> MsgTranslator parentMsg
translateMsg {onInternalMsg, onNavigate} msg =
    case msg of
        ForParent (Navigate path) ->
            onNavigate path

        ForSelf internalMsg ->
            onInternalMsg internalMsg


update : InternalMsg -> Maybe Authenticator.Model.Authentication -> SearchCriteria -> Model -> ( Model, Cmd Msg )
update msg authenticationMaybe searchCriteria model =
    case msg of
        Error err ->
            let
                _ = Debug.log "Statements Error" err
            in
                ( model, Cmd.none )

        FlagAbuse statementId ->
            let
                cmd =
                    case authenticationMaybe of
                        Just authentication ->
                            Task.perform
                                (\err -> ForSelf (FlagAbuseError err))
                                (\body -> ForSelf (FlaggedAbuse body))
                                (newTaskFlagAbuse authentication statementId)
                        Nothing ->
                            Cmd.none
            in
                ( model, cmd )

        FlagAbuseError err ->
            let
                _ = Debug.log "Flag Abuse Error" err
            in
                ( model, Cmd.none )

        FlaggedAbuse body ->
            ( updateFromDataId body.data model, makeUrl ("/statements/" ++ body.data.id) |> Navigation.newUrl )

        Load ->
            let
                -- cmd = if model.loaded
                --     then
                --         Cmd.none
                --     else
                --         Task.perform
                --             (\msg -> ForSelf (Error msg))
                --             (\msg -> ForSelf (Loaded msg))
                --             (newTaskGetStatements authenticationMaybe searchCriteria)
                cmd = Task.perform
                    (\msg -> ForSelf (Error msg))
                    (\msg -> ForSelf (Loaded msg))
                    (newTaskGetStatements authenticationMaybe searchCriteria)
            in
                ( model, cmd )

        Loaded body ->
            ( { model
                | ballotById = body.data.ballots
                , loaded = True
                , statementById = body.data.statements
                , statementIds = body.data.ids
                }
            , Cmd.none
            )

        NewStatementMsg childMsg ->
            let
                (newStatementModel, childEffect, dataMaybe) =
                    NewStatement.update childMsg authenticationMaybe model.newStatementModel
                model1 = case dataMaybe of
                    Just data ->
                        updateFromDataId data model
                    Nothing ->
                        model
            in
                ( { model1 | newStatementModel = newStatementModel }
                , Cmd.map (\msg -> ForSelf (NewStatementMsg msg)) childEffect
                )

        Rated body ->
            ( updateFromDataId body.data model, Cmd.none )

        RateError err ->
            let
                _ = Debug.log "Existing Statement Rate Error" err
            in
                (model, Cmd.none)

        RatingChanged ratingMaybe statementId ->
            let
                cmd =
                    case authenticationMaybe of
                        Just authentication ->
                            case ratingMaybe of
                                Just rating ->
                                    Task.perform
                                        (\err -> ForSelf (RateError err))
                                        (\body -> ForSelf (Rated body))
                                        (newTaskRateStatement authentication rating statementId)
                                Nothing ->
                                    Task.perform
                                        (\err -> ForSelf (RateError err))
                                        (\body -> ForSelf (Rated body))
                                        (newTaskDeleteStatementRating authentication statementId)
                        Nothing ->
                            Cmd.none
            in
                (model, cmd)

        StatementMsg childMsg ->
            let
                statementModel = model.statementModel
                statementmodel1 =
                    { statementModel
                    | ballotById = model.ballotById
                    , statementById = model.statementById
                    , statementIds = model.statementIds
                    }
                (statementmodel2, childEffect) = Statement.update childMsg authenticationMaybe statementmodel1
                model1 =
                    { model
                    | ballotById = statementmodel2.ballotById
                    , statementById = statementmodel2.statementById
                    , statementIds = statementmodel2.statementIds
                    , statementModel = statementmodel2
                    }
            in
                (model1, Cmd.map translateStatementMsg childEffect)


-- VIEW


view : Maybe Authenticator.Model.Authentication -> Model -> Html Msg
view authenticationMaybe model =
    case model.route of
        StatementRoute statementId ->
            let
                statementModel = model.statementModel
                statementmodel1 =
                    { statementModel
                    | ballotById = model.ballotById
                    , statementById = model.statementById
                    , statementIds = model.statementIds
                    }
            in
                Html.App.map translateStatementMsg (Statement.view authenticationMaybe statementmodel1)

        StatementsIndexRoute ->
            viewIndex authenticationMaybe model

        StatementsNotFoundRoute ->
            viewNotFound


viewIndex : Maybe Authenticator.Model.Authentication -> Model -> Html Msg
viewIndex authenticationMaybe model =
    article
        [ class "statements" ]
        [ h1 [] [ text "Statements" ]
        , ul
            [ class "list-unstyled statements-list" ]
            (List.map
                (\statementId -> viewStatementLine
                    authenticationMaybe
                    li
                    statementId
                    True
                    navigate
                    (\ratingMaybe statementId -> ForSelf (RatingChanged ratingMaybe statementId))
                    (\statementId -> ForSelf (FlagAbuse statementId))
                    model)
                model.statementIds)
        , case authenticationMaybe of
            Just authentication ->
                Html.App.map (\msg -> ForSelf (NewStatementMsg msg)) (NewStatement.view model.newStatementModel)
            Nothing ->
                text ""
        ]
