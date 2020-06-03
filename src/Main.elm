module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src)
import Html.Events


---- MODEL ----


type alias Model =
    {state : State}

type State =
    NotStarted
    | Paused
    | Playing

stateToString state =
    case state of
        NotStarted -> "not-started"
        Paused -> "paused"
        Playing -> "playing"


init : ( Model, Cmd Msg )
init =
    ( {state = Paused}, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | Play
    | Stop



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        Play ->
            ( {state = Playing}, Cmd.none )
        Stop ->
            ( {state = Paused}, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , Html.node "factory-beat-player" [Html.Attributes.attribute "state" (stateToString model.state)] []
        , Html.button
            [Html.Events.onClick Play]
            [Html.text "gogo"]
        , Html.button
            [Html.Events.onClick Stop]
            [Html.text "stopstop"]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
