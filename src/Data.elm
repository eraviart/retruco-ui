module Data exposing (..)

import Array
import Dict
import Set exposing (Set)
import Types exposing (..)


addToData : ObjectWrapper -> DataProxy a -> DataProxy a
addToData objectWrapper data =
    case objectWrapper of
        CardWrapper card ->
            { data
                | cards = Dict.insert card.id card data.cards
            }

        PropertyWrapper property ->
            { data
                | properties = Dict.insert property.id property data.properties
            }

        TypedValueWrapper typedValue ->
            { data
                | values = Dict.insert typedValue.id typedValue data.values
            }

        UserWrapper user ->
            { data
                | users = Dict.insert user.id user data.users
            }


filterDataWithIds : DataProxy a -> Set String -> DataProxy a
filterDataWithIds data ids =
    { data
        | ballots = Dict.filter (\id ballot -> Set.member ballot.statementId ids) data.ballots
        , cards = Dict.filter (\id card -> Set.member card.id ids) data.cards
        , properties = Dict.filter (\id property -> Set.member property.id ids) data.properties
        , users = Dict.filter (\id user -> Set.member user.id ids) data.users
        , values = Dict.filter (\id typedValue -> Set.member typedValue.id ids) data.values
    }


idsUsedByCardWithUsedIds : DataProxy a -> Card -> Set String -> Set String
idsUsedByCardWithUsedIds data card usedIds =
    if Set.member card.id usedIds then
        usedIds
    else
        idsUsedByStatementWithUsedIds data card usedIds


idsUsedById : DataProxy a -> String -> Set String
idsUsedById data id =
    idsUsedByIdWithUsedIds data id Set.empty


idsUsedByIds : DataProxy a -> Set String -> Set String
idsUsedByIds data ids =
    idsUsedByIdsWithUsedIds data ids Set.empty


idsUsedByIdsWithUsedIds : DataProxy a -> Set String -> Set String -> Set String
idsUsedByIdsWithUsedIds data ids usedIds =
    if Set.isEmpty ids then
        usedIds
    else
        ids
            |> Set.map (\id -> Set.toList <| idsUsedByIdWithUsedIds data id usedIds)
            |> Set.toList
            |> List.concat
            |> Set.fromList


idsUsedByIdWithUsedIds : DataProxy a -> String -> Set String -> Set String
idsUsedByIdWithUsedIds data id usedIds =
    if (String.isEmpty id) || (Set.member id usedIds) then
        usedIds
    else
        case objectWrapperFromId data id of
            Just objectWrapper ->
                idsUsedByObjectWrapperWithUsedIds data objectWrapper usedIds

            Nothing ->
                Set.insert id usedIds


idsUsedByObjectWrapperWithUsedIds : DataProxy a -> ObjectWrapper -> Set String -> Set String
idsUsedByObjectWrapperWithUsedIds data objectWrapper usedIds =
    case objectWrapper of
        CardWrapper card ->
            idsUsedByCardWithUsedIds data card usedIds

        PropertyWrapper property ->
            idsUsedByPropertyWithUsedIds data property usedIds

        TypedValueWrapper typedValue ->
            idsUsedByTypedValueWithUsedIds data typedValue usedIds

        UserWrapper user ->
            idsUsedByUserWithUsedIds data user usedIds


idsUsedByPropertyWithUsedIds : DataProxy a -> Property -> Set String -> Set String
idsUsedByPropertyWithUsedIds data property usedIds =
    if Set.member property.id usedIds then
        usedIds
    else
        usedIds
            |> idsUsedByStatementWithUsedIds data property
            |> idsUsedByIdWithUsedIds data property.keyId
            |> idsUsedByIdWithUsedIds data property.objectId
            |> idsUsedByIdWithUsedIds data property.valueId


idsUsedByStatementWithUsedIds : DataProxy a -> Statement b -> Set String -> Set String
idsUsedByStatementWithUsedIds data statement usedIds =
    -- Incomplete function for internal use only.
    -- Note: .ballotId is not added to the usedIds set because a ballot is not an object.
    usedIds
        |> Set.insert statement.id
        |> idsUsedByIdsWithUsedIds
            data
            (Set.fromList <| Dict.keys statement.qualities ++ List.concat (Dict.values statement.qualities))


idsUsedByTypedValueWithUsedIds : DataProxy a -> TypedValue -> Set String -> Set String
idsUsedByTypedValueWithUsedIds data typedValue usedIds =
    if Set.member typedValue.id usedIds then
        usedIds
    else
        usedIds
            |> idsUsedByStatementWithUsedIds data typedValue
            |> (\usedIds ->
                    case typedValue.value of
                        BooleanWrapper _ ->
                            usedIds

                        EmailWrapper _ ->
                            usedIds

                        IdsArrayWrapper ids ->
                            idsUsedByIdsWithUsedIds data (Set.fromList ids) usedIds

                        ImagePathWrapper _ ->
                            usedIds

                        NumberWrapper _ ->
                            usedIds

                        StringWrapper _ ->
                            usedIds

                        UrlWrapper _ ->
                            usedIds

                        WrongWrapper _ _ ->
                            usedIds
               )


idsUsedByUserWithUsedIds : DataProxy a -> User -> Set String -> Set String
idsUsedByUserWithUsedIds data user usedIds =
    if Set.member user.id usedIds then
        usedIds
    else
        Set.insert user.id usedIds


initData : Data
initData =
    { ballots = Dict.empty
    , cards = Dict.empty
    , collections = Dict.empty
    , properties = Dict.empty
    , users = Dict.empty
    , values = Dict.empty
    }


initDataWithId : DataWithId
initDataWithId =
    { ballots = Dict.empty
    , cards = Dict.empty
    , collections = Dict.empty
    , id = ""
    , properties = Dict.empty
    , users = Dict.empty
    , values = Dict.empty
    }


initDataWithIds : DataWithIds
initDataWithIds =
    { ballots = Dict.empty
    , cards = Dict.empty
    , collections = Dict.empty
    , ids = Array.empty
    , properties = Dict.empty
    , users = Dict.empty
    , values = Dict.empty
    }


mergeData : DataProxy a -> DataProxy b -> DataProxy b
mergeData new old =
    let
        -- Remove old ballots that are not present in new.
        filterObsoleteBallotIds =
            List.filterMap
                (\{ ballotId } ->
                    let
                        hasNewBallot =
                            case Dict.get ballotId new.ballots of
                                Just newBallot ->
                                    not newBallot.deleted

                                Nothing ->
                                    False
                    in
                        if hasNewBallot then
                            Nothing
                        else
                            case Dict.get ballotId old.ballots of
                                Just oldBallot ->
                                    if oldBallot.deleted then
                                        Just ballotId
                                    else
                                        Nothing

                                Nothing ->
                                    Just ballotId
                )

        obsoleteBallotIds =
            Set.fromList <|
                List.concat
                    [ Dict.values new.cards |> filterObsoleteBallotIds
                    , Dict.values new.properties |> filterObsoleteBallotIds
                    , Dict.values new.values |> filterObsoleteBallotIds
                    ]

        oldBallots =
            Dict.filter
                (\ballotId _ -> not <| Set.member ballotId obsoleteBallotIds)
                old.ballots
    in
        { old
            | ballots = Dict.union new.ballots oldBallots
            , cards = Dict.union new.cards old.cards
            , collections = Dict.union new.collections old.collections
            , properties = Dict.union new.properties old.properties
            , users = Dict.union new.users old.users
            , values = Dict.union new.values old.values
        }


objectWrapperFromId : DataProxy a -> String -> Maybe ObjectWrapper
objectWrapperFromId data id =
    case Dict.get id data.cards of
        Just card ->
            Just <| CardWrapper card

        Nothing ->
            case Dict.get id data.properties of
                Just property ->
                    Just <| PropertyWrapper property

                Nothing ->
                    case Dict.get id data.users of
                        Just user ->
                            Just <| UserWrapper user

                        Nothing ->
                            case Dict.get id data.values of
                                Just typedValue ->
                                    Just <| TypedValueWrapper typedValue

                                Nothing ->
                                    Nothing
