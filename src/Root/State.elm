module Root.State exposing (..)

import About.State
import Authenticator.Routes exposing (..)
import Authenticator.State
import Cards.Index.State
import Cards.Item.State
import Debates.Index.State
import Debates.New.State
import Debates.Routes exposing (..)
import Decoders
import Dom.Scroll
import Erl
import Json.Decode
import I18n
import Navigation
import Ports
import Properties.Item.State
import Proposals.Index.State
import Proposals.New.State
import Root.Types exposing (..)
import Routes exposing (..)
import Task
import Types exposing (Flags)
import Urls
import Values.Index.State
import Values.Item.State
import Values.New.State


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        authentication =
            Json.Decode.decodeValue Decoders.userDecoder flags.authentication
                |> Result.toMaybe

        navigatorLanguage =
            flags.language
                |> String.left 2
                |> String.toLower
                |> I18n.languageFromLanguageId

        language =
            navigatorLanguage |> Maybe.withDefault I18n.English
    in
        { aboutModel = Nothing
        , authentication = authentication
        , authenticatorCancelMsg = Nothing
        , authenticatorCompletionMsgs = []
        , authenticatorModel = Authenticator.State.init
        , cardModel = Nothing
        , cardsModel = Nothing
        , clearModelOnUrlUpdate = True
        , debatesModel = Nothing
        , location = location
        , navigatorLanguage = navigatorLanguage
        , newDebateModel = Nothing
        , newProposalModel = Nothing
        , newValueModel = Nothing
        , propertyModel = Nothing
        , proposalsModel = Nothing
        , route = Routes.I18nRouteWithoutLanguage ""
        , signOutMsg = Nothing
        , valueModel = Nothing
        , valuesModel = Nothing
        }
            |> update (LocationChanged location)


navigate : Model -> String -> Cmd msg
navigate model path =
    -- TODO: Better handle when currentUrLPath contains a scheme, domain name, etc and not path.
    if model.location.href /= path then
        Navigation.newUrl path
    else
        Cmd.none


requireSignIn : I18n.Language -> Navigation.Location -> Maybe Msg -> Model -> ( Model, Cmd Msg )
requireSignIn language location completionMsg model =
    ( { model
        | authenticatorCancelMsg = model.signOutMsg
        , authenticatorCompletionMsgs =
            [ NavigateFromAuthenticator location.href ]
                ++ case completionMsg of
                    Just completionMsg ->
                        [ completionMsg ]

                    Nothing ->
                        []
      }
    , Navigation.modifyUrl
        (Urls.languagePath language "/sign_in")
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    -- TODO Fix duplicate messages with port "fileContentRead", that was worked around by a "ImageSelectedStatus"
    -- constructor.
    List.filterMap identity
        [ case model.cardModel of
            Just cardModel ->
                Just <| Sub.map CardMsg (Cards.Item.State.subscriptions cardModel)

            Nothing ->
                Nothing
        , case model.newDebateModel of
            Just newDebateModel ->
                Just <| Sub.map NewDebateMsg (Debates.New.State.subscriptions newDebateModel)

            Nothing ->
                Nothing
        , case model.newProposalModel of
            Just newProposalModel ->
                Just <| Sub.map NewProposalMsg (Proposals.New.State.subscriptions newProposalModel)

            Nothing ->
                Nothing
        , case model.newValueModel of
            Just newValueModel ->
                Just <| Sub.map NewValueMsg (Values.New.State.subscriptions newValueModel)

            Nothing ->
                Nothing
        , case model.propertyModel of
            Just propertyModel ->
                Just <| Sub.map PropertyMsg (Properties.Item.State.subscriptions propertyModel)

            Nothing ->
                Nothing
        , case model.valueModel of
            Just valueModel ->
                Just <| Sub.map ValueMsg (Values.Item.State.subscriptions valueModel)

            Nothing ->
                Nothing
        ]
        |> Sub.batch


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        language =
            case model.route of
                I18nRouteWithLanguage language _ ->
                    language

                _ ->
                    I18n.English

        requireSignInOrUpdate : Msg -> ( Model, Cmd Msg )
        requireSignInOrUpdate completionMsg =
            if model.authentication == Nothing then
                -- update (StartAuthenticator Nothing (Just completionMsg) SignInRoute) model
                requireSignIn language model.location (Just completionMsg) model
            else
                update completionMsg model
    in
        case msg of
            AboutMsg childMsg ->
                case model.aboutModel of
                    Just aboutModel ->
                        let
                            ( updatedAboutModel, childCmd ) =
                                About.State.update childMsg aboutModel
                        in
                            ( { model | aboutModel = Just updatedAboutModel }
                            , Cmd.map translateAboutMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            AuthenticatorMsg childMsg ->
                let
                    ( authenticatorModel, childCmd ) =
                        Authenticator.State.update childMsg model.authenticatorModel
                in
                    ( { model | authenticatorModel = authenticatorModel }
                    , Cmd.map translateAuthenticatorMsg childCmd
                    )

            AuthenticatorTerminated route result ->
                case result of
                    Err () ->
                        ( { model
                            | authenticatorCancelMsg = Nothing
                            , authenticatorCompletionMsgs = []
                            , clearModelOnUrlUpdate = False
                          }
                        , case model.authenticatorCancelMsg of
                            Just cancelMsg ->
                                Task.perform (\_ -> cancelMsg) (Task.succeed ())

                            Nothing ->
                                navigate model <| Urls.languagePath language "/"
                        )

                    Ok authentication ->
                        { model
                            | authentication = authentication
                            , authenticatorCancelMsg = Nothing
                            , authenticatorCompletionMsgs = []
                            , clearModelOnUrlUpdate = False
                        }
                            ! ([ Ports.storeAuthentication authentication ]
                                ++ if List.isEmpty model.authenticatorCompletionMsgs then
                                    [ navigate model
                                        (case route of
                                            ChangePasswordRoute _ ->
                                                Urls.languagePath language "/profile"

                                            _ ->
                                                Urls.languagePath language "/"
                                        )
                                    ]
                                   else
                                    List.map
                                        (\completionMsg -> Task.perform (\_ -> completionMsg) (Task.succeed ()))
                                        model.authenticatorCompletionMsgs
                              )

            CardMsg childMsg ->
                case model.cardModel of
                    Just cardModel ->
                        let
                            ( updatedCardModel, childCmd ) =
                                Cards.Item.State.update childMsg cardModel
                        in
                            ( { model | cardModel = Just updatedCardModel }
                            , Cmd.map translateCardMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            CardsMsg childMsg ->
                case model.cardsModel of
                    Just cardsModel ->
                        let
                            ( updatedCardsModel, childCmd ) =
                                Cards.Index.State.update childMsg cardsModel
                        in
                            ( { model | cardsModel = Just updatedCardsModel }
                            , Cmd.map translateCardsMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            ChangeAuthenticatorRoute authenticatorRoute ->
                let
                    path =
                        case authenticatorRoute of
                            ActivateRoute userId ->
                                "/users/" ++ userId ++ "/activate"

                            ChangePasswordRoute userId ->
                                "/users/" ++ userId ++ "/reset-password"

                            ResetPasswordRoute ->
                                "/reset_password"

                            SignInRoute ->
                                "/sign_in"

                            SignOutRoute ->
                                "/sign_out"

                            SignUpRoute ->
                                "/sign_up"
                in
                    ( model
                    , navigate model <| Urls.languagePath language path
                    )

            DebatesMsg childMsg ->
                case model.debatesModel of
                    Just debatesModel ->
                        let
                            ( updatedDebatesModel, childCmd ) =
                                Debates.Index.State.update childMsg debatesModel
                        in
                            ( { model | debatesModel = Just updatedDebatesModel }
                            , Cmd.map translateDebatesMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            DebateUpserted data ->
                update (Navigate <| Urls.languagePath language <| Urls.idToPath data data.id) model

            LocationChanged location ->
                urlUpdate location model

            Navigate path ->
                ( case model.authentication of
                    Just _ ->
                        model

                    Nothing ->
                        { model | signOutMsg = Just (NavigateFromAuthenticator model.location.href) }
                , navigate model path
                )

            NavigateFromAuthenticator path ->
                ( model, navigate model path )

            NewDebateMsg childMsg ->
                case model.newDebateModel of
                    Just newDebateModel ->
                        let
                            ( updatedNewDebateModel, childCmd ) =
                                Debates.New.State.update childMsg newDebateModel
                        in
                            ( { model | newDebateModel = Just updatedNewDebateModel }
                            , Cmd.map translateNewDebateMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            NewProposalMsg childMsg ->
                case model.newProposalModel of
                    Just newProposalModel ->
                        let
                            ( updatedNewProposalModel, childCmd ) =
                                Proposals.New.State.update childMsg newProposalModel
                        in
                            ( { model | newProposalModel = Just updatedNewProposalModel }
                            , Cmd.map translateNewProposalMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            NewValueMsg childMsg ->
                case model.newValueModel of
                    Just newValueModel ->
                        let
                            ( updatedNewValueModel, childCmd ) =
                                Values.New.State.update childMsg newValueModel
                        in
                            ( { model | newValueModel = Just updatedNewValueModel }
                            , Cmd.map translateNewValueMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            NoOp ->
                ( model, Cmd.none )

            PropertyMsg childMsg ->
                case model.propertyModel of
                    Just propertyModel ->
                        let
                            ( updatedPropertyModel, childCmd ) =
                                Properties.Item.State.update childMsg propertyModel
                        in
                            ( { model | propertyModel = Just updatedPropertyModel }
                            , Cmd.map translatePropertyMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            ProposalsMsg childMsg ->
                case model.proposalsModel of
                    Just proposalsModel ->
                        let
                            ( updatedProposalsModel, childCmd ) =
                                Proposals.Index.State.update childMsg proposalsModel
                        in
                            ( { model | proposalsModel = Just updatedProposalsModel }
                            , Cmd.map translateProposalsMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            ProposalUpserted data ->
                update (Navigate <| Urls.languagePath language <| Urls.idToPath data data.id) model

            RequireSignInForCard cardCompletionMsg ->
                requireSignInOrUpdate <| CardMsg cardCompletionMsg

            RequireSignInForNewDebate newDebateCompletionMsg ->
                requireSignInOrUpdate <| NewDebateMsg newDebateCompletionMsg

            RequireSignInForNewProposal newProposalCompletionMsg ->
                requireSignInOrUpdate <| NewProposalMsg newProposalCompletionMsg

            RequireSignInForNewValue newValueCompletionMsg ->
                requireSignInOrUpdate <| NewValueMsg newValueCompletionMsg

            RequireSignInForProperty propertyCompletionMsg ->
                requireSignInOrUpdate <| PropertyMsg propertyCompletionMsg

            RequireSignInForValue valueCompletionMsg ->
                requireSignInOrUpdate <| ValueMsg valueCompletionMsg

            ValueMsg childMsg ->
                case model.valueModel of
                    Just valueModel ->
                        let
                            ( updatedValueModel, childCmd ) =
                                Values.Item.State.update childMsg valueModel
                        in
                            ( { model | valueModel = Just updatedValueModel }
                            , Cmd.map translateValueMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            ValuesMsg childMsg ->
                case model.valuesModel of
                    Just valuesModel ->
                        let
                            ( updatedValuesModel, childCmd ) =
                                Values.Index.State.update childMsg valuesModel
                        in
                            ( { model | valuesModel = Just updatedValuesModel }
                            , Cmd.map translateValuesMsg childCmd
                            )

                    Nothing ->
                        ( model, Cmd.none )

            ValueUpserted data ->
                update (Navigate <| Urls.languagePath language <| Urls.idToPath data data.id) model


urlUpdate : Navigation.Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    let
        clearSubModels =
            model.clearModelOnUrlUpdate

        cleanModel =
            if clearSubModels then
                { model
                    | aboutModel = Nothing
                    , cardModel = Nothing
                    , cardsModel = Nothing
                    , clearModelOnUrlUpdate = True
                    , debatesModel = Nothing
                    , newDebateModel = Nothing
                    , newProposalModel = Nothing
                    , newValueModel = Nothing
                    , propertyModel = Nothing
                    , proposalsModel = Nothing
                    , valueModel = Nothing
                    , valuesModel = Nothing
                }
            else
                { model
                    | clearModelOnUrlUpdate = True
                }

        ( newModel, cmd ) =
            case parseLocation location of
                Just ((I18nRouteWithLanguage language localizedRoute) as route) ->
                    let
                        ( localizedModel, localizedCmd ) =
                            case localizedRoute of
                                AboutRoute ->
                                    let
                                        aboutModel =
                                            case model.aboutModel of
                                                Just existingAboutModel ->
                                                    existingAboutModel

                                                Nothing ->
                                                    About.State.init model.authentication language

                                        ( updatedAboutModel, updatedAboutCmd ) =
                                            About.State.urlUpdate location aboutModel
                                    in
                                        ( { cleanModel | aboutModel = Just updatedAboutModel }
                                        , Cmd.map translateAboutMsg updatedAboutCmd
                                        )

                                AuthenticatorRoute authenticatorRoute ->
                                    let
                                        ( authenticatorModel, childCmd ) =
                                            Authenticator.State.urlUpdate
                                                language
                                                location
                                                authenticatorRoute
                                                model.authenticatorModel
                                    in
                                        ( { -- Don't use cleanModel instead of model, because we want to go back to
                                            -- current sub-model after authenticator process.
                                            model
                                            | authenticatorModel = authenticatorModel
                                            , authenticatorCancelMsg =
                                                if model.authenticatorCancelMsg == Nothing then
                                                    Just (NavigateFromAuthenticator model.location.href)
                                                else
                                                    model.authenticatorCancelMsg
                                            , authenticatorCompletionMsgs =
                                                if List.isEmpty model.authenticatorCompletionMsgs then
                                                    if authenticatorRoute == SignOutRoute then
                                                        case model.signOutMsg of
                                                            Just signOutMsg ->
                                                                [ signOutMsg ]

                                                            Nothing ->
                                                                []
                                                    else
                                                        [ NavigateFromAuthenticator model.location.href ]
                                                else
                                                    model.authenticatorCompletionMsgs
                                          }
                                        , Cmd.map translateAuthenticatorMsg childCmd
                                        )

                                CardsRoute cardsRoute ->
                                    case cardsRoute of
                                        CardRoute cardId cardRoute ->
                                            let
                                                cardModel =
                                                    Cards.Item.State.init model.authentication language cardId

                                                ( updatedCardModel, updatedCardCmd ) =
                                                    Cards.Item.State.urlUpdate
                                                        location
                                                        cardRoute
                                                        cardModel
                                            in
                                                ( { cleanModel | cardModel = Just updatedCardModel }
                                                , Cmd.map translateCardMsg updatedCardCmd
                                                )

                                        CardsIndexRoute ->
                                            let
                                                cardsModel =
                                                    Cards.Index.State.init model.authentication language

                                                ( updatedCardsModel, childCmd ) =
                                                    Cards.Index.State.urlUpdate
                                                        location
                                                        cardsModel
                                            in
                                                ( { cleanModel | cardsModel = Just updatedCardsModel }
                                                , Cmd.map translateCardsMsg childCmd
                                                )

                                DebatesRoute childRoute ->
                                    case childRoute of
                                        DebatesIndexRoute ->
                                            let
                                                debatesModel =
                                                    Debates.Index.State.init model.authentication language

                                                ( updatedDebatesModel, childCmd ) =
                                                    Debates.Index.State.urlUpdate location debatesModel
                                            in
                                                ( { cleanModel | debatesModel = Just updatedDebatesModel }
                                                , Cmd.map translateDebatesMsg childCmd
                                                )

                                        NewDebateRoute ->
                                            let
                                                newDebateModel =
                                                    case ( model.newDebateModel, clearSubModels ) of
                                                        ( Just newDebateModel, False ) ->
                                                            Debates.New.State.setContext
                                                                model.authentication
                                                                language
                                                                newDebateModel

                                                        _ ->
                                                            Debates.New.State.init
                                                                model.authentication
                                                                language

                                                ( updatedNewDebateModel, updatedNewDebateCmd ) =
                                                    Debates.New.State.urlUpdate location newDebateModel
                                            in
                                                ( { cleanModel
                                                    | newDebateModel = Just updatedNewDebateModel
                                                    , signOutMsg =
                                                        Just <|
                                                            NavigateFromAuthenticator <|
                                                                Urls.languagePath language "/debates"
                                                  }
                                                , Cmd.map translateNewDebateMsg updatedNewDebateCmd
                                                )

                                HomeRoute ->
                                    ( cleanModel, navigate cleanModel <| Urls.languagePath language "/proposals" )

                                -- NewCardRoute ->
                                --     case model.authentication of
                                --         Just _ ->
                                --             let
                                --                 ( newCardModel, childCmd ) =
                                --                     NewCards.Item.State.urlUpdate
                                --                         model.authentication
                                --                         language
                                --                         location
                                --                         model.newCardModel
                                --             in
                                --                 ( { cleanModel
                                --                     | newCardModel = newCardModel
                                --                     , signOutMsg =
                                --                         Just <|
                                --                             NavigateFromAuthenticator <|
                                --                                 Urls.languagePath language "/cards"
                                --                   }
                                --                 , Cmd.map translateNewCardMsg childCmd
                                --                 )
                                --         Nothing ->
                                --             requireSignIn language location Nothing cleanModel
                                NotFoundRoute _ ->
                                    ( cleanModel
                                    , Ports.setDocumentMetadata
                                        { description = I18n.translate language I18n.PageNotFoundDescription
                                        , imageUrl = Urls.appLogoFullUrl
                                        , title = I18n.translate language I18n.PageNotFound
                                        }
                                    )

                                PropertiesRoute childRoute ->
                                    case childRoute of
                                        PropertyRoute propertyId propertyRoute ->
                                            let
                                                propertyModel =
                                                    case ( model.propertyModel, clearSubModels ) of
                                                        ( Just propertyModel, False ) ->
                                                            Properties.Item.State.setContext
                                                                model.authentication
                                                                language
                                                                propertyModel

                                                        _ ->
                                                            Properties.Item.State.init
                                                                model.authentication
                                                                language
                                                                propertyId

                                                ( updatedPropertyModel, updatedPropertyCmd ) =
                                                    Properties.Item.State.urlUpdate
                                                        location
                                                        propertyRoute
                                                        propertyModel
                                            in
                                                ( { cleanModel
                                                    | propertyModel = Just updatedPropertyModel
                                                    , -- Stay at the current location after sign out.
                                                      signOutMsg = Just (NavigateFromAuthenticator location.href)
                                                  }
                                                , Cmd.map translatePropertyMsg updatedPropertyCmd
                                                )

                                ProposalsRoute childRoute ->
                                    case childRoute of
                                        ProposalsIndexRoute ->
                                            let
                                                proposalsModel =
                                                    Proposals.Index.State.init model.authentication language

                                                ( updatedProposalsModel, childCmd ) =
                                                    Proposals.Index.State.urlUpdate location proposalsModel
                                            in
                                                ( { cleanModel | proposalsModel = Just updatedProposalsModel }
                                                , Cmd.map translateProposalsMsg childCmd
                                                )

                                        NewProposalRoute ->
                                            let
                                                newProposalModel =
                                                    case ( model.newProposalModel, clearSubModels ) of
                                                        ( Just newProposalModel, False ) ->
                                                            Proposals.New.State.setContext
                                                                model.authentication
                                                                language
                                                                newProposalModel

                                                        _ ->
                                                            Proposals.New.State.init
                                                                model.authentication
                                                                language

                                                ( updatedNewProposalModel, updatedNewProposalCmd ) =
                                                    Proposals.New.State.urlUpdate location newProposalModel
                                            in
                                                ( { cleanModel
                                                    | newProposalModel = Just updatedNewProposalModel
                                                    , signOutMsg =
                                                        Just <|
                                                            NavigateFromAuthenticator <|
                                                                Urls.languagePath language "/proposals"
                                                  }
                                                , Cmd.map translateNewProposalMsg updatedNewProposalCmd
                                                )

                                UserProfileRoute ->
                                    ( cleanModel, Cmd.none )

                                ValuesRoute childRoute ->
                                    case childRoute of
                                        NewValueRoute ->
                                            case model.authentication of
                                                Just _ ->
                                                    let
                                                        newValueModel =
                                                            Values.New.State.init model.authentication language []

                                                        ( updatedNewValueModel, updatedNewValueCmd ) =
                                                            Values.New.State.urlUpdate location newValueModel
                                                    in
                                                        ( { cleanModel
                                                            | newValueModel = Just updatedNewValueModel
                                                            , signOutMsg =
                                                                Just <|
                                                                    NavigateFromAuthenticator <|
                                                                        Urls.languagePath language "/values"
                                                          }
                                                        , Cmd.map translateNewValueMsg updatedNewValueCmd
                                                        )

                                                Nothing ->
                                                    requireSignIn language location Nothing cleanModel

                                        ValueRoute valueId valueRoute ->
                                            let
                                                valueModel =
                                                    case ( model.valueModel, clearSubModels ) of
                                                        ( Just valueModel, False ) ->
                                                            Values.Item.State.setContext
                                                                model.authentication
                                                                language
                                                                valueModel

                                                        _ ->
                                                            Values.Item.State.init
                                                                model.authentication
                                                                language
                                                                valueId

                                                ( updatedValueModel, updatedValueCmd ) =
                                                    Values.Item.State.urlUpdate
                                                        location
                                                        valueRoute
                                                        valueModel
                                            in
                                                ( { cleanModel
                                                    | valueModel = Just updatedValueModel
                                                    , -- Stay at the current location after sign out.
                                                      signOutMsg = Just (NavigateFromAuthenticator location.href)
                                                  }
                                                , Cmd.map translateValueMsg updatedValueCmd
                                                )

                                        ValuesIndexRoute ->
                                            let
                                                valuesModel =
                                                    Values.Index.State.init model.authentication language

                                                ( updatedValuesModel, childCmd ) =
                                                    Values.Index.State.urlUpdate location valuesModel
                                            in
                                                ( { cleanModel | valuesModel = Just updatedValuesModel }
                                                , Cmd.map translateValuesMsg childCmd
                                                )
                    in
                        ( { localizedModel | route = route }, localizedCmd )

                Just ((I18nRouteWithoutLanguage path) as route) ->
                    let
                        language =
                            model.navigatorLanguage |> Maybe.withDefault I18n.English

                        command =
                            Urls.languagePath language
                                (path ++ (Urls.queryStringForParams [ "q", "tagIds" ] location))
                                |> Navigation.modifyUrl
                    in
                        ( { cleanModel | route = route }, command )

                Nothing ->
                    let
                        language =
                            model.navigatorLanguage |> Maybe.withDefault I18n.English

                        url =
                            location.href
                                |> Erl.parse

                        newUrl =
                            { url | path = (I18n.languageIdFromLanguage language) :: url.path }
                    in
                        ( cleanModel, Navigation.modifyUrl (Erl.toString newUrl) )
    in
        { newModel | location = location }
            ! [ Task.attempt
                    (\result ->
                        case result of
                            Err err ->
                                Debug.crash ("Dom.Scroll.toTop \"html-element\": " ++ toString err)

                            Ok _ ->
                                NoOp
                    )
                    (Dom.Scroll.toTop "html-element")
              , cmd
              ]
