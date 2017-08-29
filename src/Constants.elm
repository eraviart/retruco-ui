module Constants exposing (..)

-- KEYS


debateKeyIds : List String
debateKeyIds =
    [ "cons", "options", "pros", "sources" ]


imageLogoPathKeyIds : List String
imageLogoPathKeyIds =
    [ "logo" ]


imageScreenshotPathKeyIds : List String
imageScreenshotPathKeyIds =
    [ "screenshot" ]


imagePathKeyIds : List String
imagePathKeyIds =
    imageLogoPathKeyIds ++ imageScreenshotPathKeyIds


nameKeyIds : List String
nameKeyIds =
    [ "name" ]
