module Statements.ViewsHelpers exposing (..)

import Constants exposing (imagePathKeyIds)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onClick, onWithOptions)
import Html.Helpers exposing (aForPath)
import Http
import I18n
import Json.Decode
import LineViews exposing (viewPropertyIdLine)
import LocalizedStrings
import Set exposing (Set)
import Types exposing (Argument, DataProxy)
import Urls


viewDebatePropertiesBlock :
    I18n.Language
    -> (String -> msg)
    -> DataProxy a
    -> List String
    -> Html msg
viewDebatePropertiesBlock language navigateMsg data debatePropertyIds =
    div []
        [ h2 [] [ text <| I18n.translate language I18n.Arguments ]
        , if List.isEmpty debatePropertyIds then
            p [] [ text <| I18n.translate language I18n.MissingArguments ]
          else
            ul [ class "list-group" ]
                (List.map
                    (\debatePropertyId ->
                        li [ class "d-flex flex-nowrap justify-content-between list-group-item" ]
                            [ viewPropertyIdLine language (Just navigateMsg) False data debatePropertyId
                            , viewStatementIdRatingPanel language navigateMsg data debatePropertyId
                            ]
                    )
                    debatePropertyIds
                )
        ]


viewStatementIdRatingPanel : I18n.Language -> (String -> msg) -> DataProxy a -> String -> Html msg
viewStatementIdRatingPanel language navigateMsg data statementId =
    case Dict.get statementId data.cards of
        Just card ->
            viewStatementRatingPanel language navigateMsg (Just "cards") card

        Nothing ->
            case Dict.get statementId data.properties of
                Just property ->
                    viewStatementRatingPanel language navigateMsg (Just "properties") property

                Nothing ->
                    case Dict.get statementId data.values of
                        Just typedValue ->
                            viewStatementRatingPanel language navigateMsg (Just "affirmations") typedValue

                        Nothing ->
                            i [ class "text-warning" ] [ text (I18n.translate language <| I18n.UnknownId statementId) ]


viewStatementRatingPanel :
    I18n.Language
    -> (String -> msg)
    -> Maybe String
    -> { a | argumentCount : Int, id : String, ratingCount : Int, ratingSum : Int, trashed : Bool }
    -> Html msg
viewStatementRatingPanel language navigateMsg objectsUrlName { argumentCount, id, ratingCount, ratingSum, trashed } =
    let
        buttonClass =
            classList
                [ ( "btn", True )
                , ( "btn-lg", True )
                , ( if trashed then
                        "btn-danger"
                    else if ratingSum > 0 then
                        "btn-outline-success"
                    else
                        "btn-outline-danger"
                  , True
                  )
                , ( "ml-3", True )
                ]

        buttonWithAttributes =
            case objectsUrlName of
                Just objectsUrlName ->
                    aForPath
                        navigateMsg
                        language
                        ("/" ++ objectsUrlName ++ "/" ++ id)
                        [ buttonClass ]

                Nothing ->
                    button
                        [ buttonClass
                        , disabled True
                        , type_ "button"
                        ]
    in
        buttonWithAttributes
            [ strong [] [ text <| toString ratingSum ]
            , text " / "
            , text <|
                I18n.translate
                    language
                    (I18n.CountVotes ratingCount)
            , br [] []
            , text <|
                I18n.translate
                    language
                    (I18n.CountArguments argumentCount)
            ]


viewStatementRatingToolbar :
    I18n.Language
    -> (Maybe Int -> msg)
    -> msg
    -> DataProxy a
    -> { b | ballotId : String }
    -> Html msg
viewStatementRatingToolbar language rateMsg trashMsg data { ballotId } =
    div
        [ class "toolbar"
        , role "toolbar"
        ]
        [ let
            ballot =
                Dict.get ballotId data.ballots

            ballotRating =
                Maybe.map .rating ballot
          in
            div
                [ ariaLabel "Rating panel"
                , class "btn-group"
                , role "group"
                ]
                [ button
                    [ ariaPressed (ballotRating == Just 1)
                    , classList
                        [ ( "active", ballotRating == Just 1 )
                        , ( "btn", True )
                        , ( "btn-outline-success", True )
                        ]
                    , onClick
                        (if ballotRating == Just 1 then
                            rateMsg Nothing
                         else
                            rateMsg (Just 1)
                        )
                    , type_ "button"
                    ]
                    [ span
                        [ ariaHidden True
                        , class "fa fa-thumbs-o-up"
                        ]
                        []
                    , text " "
                    , text <|
                        I18n.translate
                            language
                            I18n.Agree
                    ]
                , button
                    [ ariaPressed (ballotRating == Just 0)
                    , classList
                        [ ( "active", ballotRating == Just 0 )
                        , ( "btn", True )
                        , ( "btn-outline-secondary", True )
                        ]
                    , onClick
                        (if ballotRating == Just 0 then
                            rateMsg Nothing
                         else
                            rateMsg (Just 0)
                        )
                    , type_ "button"
                    ]
                    [ span
                        [ ariaHidden True
                        , class "fa fa-square-o"
                        ]
                        []
                    , text " "
                    , text <|
                        I18n.translate
                            language
                            I18n.Abstain
                    ]
                , button
                    [ ariaPressed (ballotRating == Just -1)
                    , classList
                        [ ( "active", ballotRating == Just -1 )
                        , ( "btn", True )
                        , ( "btn-outline-danger", True )
                        ]
                    , onClick
                        (if ballotRating == Just -1 then
                            rateMsg Nothing
                         else
                            rateMsg (Just -1)
                        )
                    , type_ "button"
                    ]
                    [ span
                        [ ariaHidden True
                        , class "fa fa-thumbs-o-down"
                        ]
                        []
                    , text " "
                    , text <|
                        I18n.translate
                            language
                            I18n.Disagree
                    ]
                ]
        , text " "
        , button
            [ classList
                [ ( "btn", True )
                , ( "btn-danger", True )
                ]
            , onClick trashMsg
            , type_ "button"
            ]
            [ span
                [ ariaHidden True
                , class "fa fa-trash-o"
                ]
                []
            , text " "
            , text <|
                I18n.translate
                    language
                    I18n.Trash
            ]
        ]


viewStatementSocialToolbar :
    I18n.Language
    -> (String -> msg)
    -> (String -> msg)
    -> (String -> msg)
    -> (String -> msg)
    -> DataProxy a
    -> { b | id : String }
    -> Html msg
viewStatementSocialToolbar language shareOnFacebookMsg shareOnGooglePlusMsg shareOnLinkedInMsg shareOnTwitterMsg data { id } =
    div
        [ class "toolbar"
        , role "toolbar"
        ]
        [ let
            statementString =
                LocalizedStrings.idToString language data id

            imageUrl =
                case Dict.get id data.cards of
                    Just card ->
                        LocalizedStrings.statementPropertiesToString imagePathKeyIds language data card
                            |> Maybe.withDefault Urls.appLogoFullUrl

                    Nothing ->
                        case Dict.get id data.properties of
                            Just property ->
                                LocalizedStrings.statementPropertiesToString imagePathKeyIds language data property
                                    |> Maybe.withDefault Urls.appLogoFullUrl

                            Nothing ->
                                case Dict.get id data.values of
                                    Just typedValue ->
                                        LocalizedStrings.statementPropertiesToString imagePathKeyIds
                                            language
                                            data
                                            typedValue
                                            |> Maybe.withDefault Urls.appLogoFullUrl

                                    Nothing ->
                                        Urls.appLogoFullUrl

            url =
                Urls.statementIdPath data id
                    |> Urls.languagePath language
                    |> Urls.fullUrl

            facebookUrl =
                "http://www.facebook.com/sharer.php?s=100&p[title]="
                    ++ Http.encodeUri statementString
                    ++ "&p[summary]="
                    ++ Http.encodeUri (I18n.translate language (I18n.TweetMessage statementString url))
                    ++ "&p[url]="
                    ++ Http.encodeUri url
                    ++ "&p[images][0]="
                    ++ Http.encodeUri imageUrl

            googlePlusUrl =
                "https://plus.google.com/share?url=" ++ Http.encodeUri url

            linkedInUrl =
                "https://www.linkedin.com/shareArticle?mini=true&url="
                    ++ Http.encodeUri url
                    ++ "&title="
                    ++ Http.encodeUri statementString
                    ++ "&summary="
                    ++ Http.encodeUri (I18n.translate language (I18n.TweetMessage statementString url))
                    ++ "&source="
                    ++ Http.encodeUri "OGP Toolbox"

            twitterUrl =
                "https://twitter.com/intent/tweet?text="
                    ++ Http.encodeUri (I18n.translate language (I18n.TweetMessage statementString url))
          in
            div []
                [ a
                    [ class "btn btn-light"
                    , href facebookUrl
                    , onWithOptions
                        "click"
                        { stopPropagation = True, preventDefault = True }
                        (Json.Decode.succeed (shareOnFacebookMsg facebookUrl))
                    ]
                    [ i [ attribute "aria-hidden" "true", class "fa fa-facebook" ] [] ]
                , a
                    [ class "btn btn-light"
                    , href googlePlusUrl
                    , onWithOptions
                        "click"
                        { stopPropagation = True, preventDefault = True }
                        (Json.Decode.succeed (shareOnGooglePlusMsg googlePlusUrl))
                    ]
                    [ i [ attribute "aria-hidden" "true", class "fa fa-google-plus" ] [] ]
                , a
                    [ class "btn btn-light"
                    , href linkedInUrl
                    , onWithOptions
                        "click"
                        { stopPropagation = True, preventDefault = True }
                        (Json.Decode.succeed (shareOnLinkedInMsg linkedInUrl))
                    ]
                    [ i [ attribute "aria-hidden" "true", class "fa fa-linkedin" ] [] ]
                , a
                    [ class "btn btn-light"
                    , href twitterUrl
                    , onWithOptions
                        "click"
                        { stopPropagation = True, preventDefault = True }
                        (Json.Decode.succeed (shareOnTwitterMsg twitterUrl))
                    ]
                    [ i [ attribute "aria-hidden" "true", class "fa fa-twitter" ] [] ]
                ]
        ]
