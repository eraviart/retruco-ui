module Root.Types exposing (..)

import Authenticator.Routes
import Authenticator.Types exposing (Authentication)
import I18n
import Navigation
import NewValue.Types
import Routes
import Search
import Types
import Value.Types
import Values.Types


type alias Model =
    { authentication : Maybe Authentication
    , authenticatorCancelMsg : Maybe Msg
    , authenticatorCompletionMsg : Maybe Msg
    , authenticatorModel : Authenticator.Types.Model
    , location : Navigation.Location
    , navigatorLanguage : Maybe I18n.Language
    , newValueModel : NewValue.Types.Model
    , page : String
    , route : Routes.Route
    , searchCriteria : Types.SearchCriteria
    , searchModel : Search.Model
    , signOutMsg : Maybe Msg
    , valueModel : Value.Types.Model
    , valuesModel : Values.Types.Model
    }


type Msg
    = AuthenticatorMsg Authenticator.Types.InternalMsg
    | AuthenticatorTerminated Authenticator.Routes.Route (Result () (Maybe Authentication))
    | ChangeAuthenticatorRoute Authenticator.Routes.Route
    | LocationChanged Navigation.Location
    | Navigate String
    | NavigateFromAuthenticator String
    | NewValueMsg NewValue.Types.InternalMsg
    | NoOp
    | SearchMsg Search.InternalMsg
    | ValueMsg Value.Types.InternalMsg
    | ValuesMsg Values.Types.InternalMsg


translateAuthenticatorMsg : Authenticator.Types.MsgTranslator Msg
translateAuthenticatorMsg =
    Authenticator.Types.translateMsg
        { onChangeRoute = ChangeAuthenticatorRoute
        , onInternalMsg = AuthenticatorMsg
        , onNavigate = NavigateFromAuthenticator
        , onTerminated = AuthenticatorTerminated
        }


translateNewValueMsg : NewValue.Types.MsgTranslator Msg
translateNewValueMsg =
    NewValue.Types.translateMsg
        { onInternalMsg = NewValueMsg
        , onNavigate = Navigate
        }


translateValueMsg : Value.Types.MsgTranslator Msg
translateValueMsg =
    Value.Types.translateMsg
        { onInternalMsg = ValueMsg
        , onNavigate = Navigate
        }


translateValuesMsg : Values.Types.MsgTranslator Msg
translateValuesMsg =
    Values.Types.translateMsg
        { onInternalMsg = ValuesMsg
        , onNavigate = Navigate
        }


translateSearchMsg : Search.MsgTranslator Msg
translateSearchMsg =
    Search.translateMsg
        { onInternalMsg = SearchMsg
        , onNavigate = Navigate
        }



-- translateStatementsMsg : Statements.MsgTranslator Msg
-- translateStatementsMsg =
--     Statements.translateMsg
--         { onInternalMsg = StatementsMsg
--         , onNavigate = Navigate
--         }
