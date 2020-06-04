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


quote = """
    I think any time somebody considers what they want from an advanced economy
    or an economy in a situation where technology is getting better and better
    is they should want more and more of the economy to essentially be about subjective values.
    About things like entertainment, cosmetics and sports and lifestyle and design and all that.
    That's what we should want because that's a signal that we are creating technologies and an economy that's really
    serving us.
    """

-- Jaron Lanier, Making Sense Podcast #135, minute 11

---- VIEW ----


view : Model -> Html Msg
view model =
    Html.article []
        -- intro
        [ h1 [Html.Attributes.class "title"] [ text "Jan Wirth - Artist Residency application"]
        , Html.p [Html.Attributes.class "quote"] [text quote]
        , Html.p [Html.Attributes.class "intro-text"]
            [ Html.text "My name is Jan. And you are reading this because after learning about the artist residency I just could not sleep. I could not sleep because I got very inspired."
            , Html.text "The general concept of the residency inspires me because I am passionate about technology and its implications for how we think, live and love."
            , Html.text "The themes perfectly match my profile. I am a creative technologist with a background in arts and design."
            , Html.text "Right now, you are looking at a mix between a non-stage live music experience and sound installation. It is composed, designed and hand-coded just for you."
            , Html.text "I want to show how keen I am to work with the most ambitious people in experimental arts and technology and be part of something meaningful. So I put in the work."
            , Html.text "I hope this experience helps you evaluate if and why I should be part of the artist residency program."
            ]
        , Html.section [Html.Attributes.class "player"][
              Html.h2 [] [Html.text "Hit play"]
            , playButton model
            , Html.node "factory-beat-player" [Html.Attributes.attribute "state" (stateToString model.state)] []
        ]
        -- what I do
        -- scalab, music, arts
        -- what I did
        -- ef, mercedes
        -- talks in singapor and lisbon
        -- outro
        ]

playButton : Model -> Html.Html Msg
playButton {state} =
    case state of
        NotStarted ->
            Html.button
                [Html.Events.onClick Play]
                [Html.text "gogo"]
        Paused ->
            Html.button
                [Html.Events.onClick Play]
                [Html.text "gogo"]
        Playing ->
            Html.button
                [Html.Events.onClick Stop]
                [Html.text "stopstop"]

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
