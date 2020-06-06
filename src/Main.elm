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


quote = Html.p [Html.Attributes.class "quote"] [
    Html.text "I think any time somebody considers what they want from"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "an economy in a situation where technology is getting better and better is"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "more of the economy to essentially be about subjective values."
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "Because that's a signal that we are creating technologies and an economy that's really "
    , Html.span [Html.Attributes.class "nowrap"] [Html.text "serving us."]
    ]

-- Jaron Lanier, Making Sense Podcast #135, minute 11

---- VIEW ----


view : Model -> Html Msg
view model =
    Html.article []
        -- intro
        [ h1 [Html.Attributes.class "title"] [ text "Jan Wirth - Artist Residency application"]
        , quote
        , Html.p [Html.Attributes.class "quote-source"] [
            Html.text "Jaron Lanier, Philosopher, Artist, Technologist"
        ]
        , Html.p [Html.Attributes.class "intro-text"]
            [ Html.text "Hello There! My name is Jan. And you are reading this because after learning about the artist residency I just could not sleep. I could not sleep because I got very inspired."
            , Html.text "The general concept of the residency inspires me because I am passionate about technology and its implications for how we think, live and love."
            , Html.text "The topics perfectly match my profile. I am a creative technologist with a background in arts and design."
            , Html.text "Right now, you are looking at a mix between a non-stage live music experience and sound installation. It is composed, designed and hand-coded just for you."
            , Html.text "I want to show how keen I am to work with the most ambitious people in experimental arts and technology and be part of something meaningful. So I put in the work."
            , Html.text "I hope this experience helps you evaluate if and why I should be part of the artist residency program."
            ]
        , Html.section [Html.Attributes.class "player"][
            playButton model
            , Html.node "factory-beat-player" [Html.Attributes.attribute "state" (stateToString model.state)] []
        ]
        -- what I do
        , Html.h2 [] [Html.text "Some Projects"]
        , Html.p [Html.Attributes.class "maff"] [
            Html.a [ Html.Attributes.href "https://github.com/FranzSkuffka/maff"] [Html.text "Maff"]
           , Html.text " is a Telegram bot that helps you transcribe mathematical terms into LaTeX, reducing the need for scientist to learn special syntax for experession mathematical equations. "
           , Html.text "Maff uses computer vision technology to do its job. I wrote it in on a misty sunday afternoon."
           ]
        , Html.div [Html.Attributes.class "img maff-picture"] [
            Html.img [Html.Attributes.src "/maff.png"] []
        ]

        , Html.p [Html.Attributes.class "scalab-text"] [
              Html.h2 [] [Html.text "Professional Experience"]
            , Html.text "I am the CTO of "
            , Html.a [Html.Attributes.href "https://scalab.app"] [Html.text "scalab.app"]
            , Html.text ". We are working on technology that makes complex web app development accessible to more humans. "
            , Html.text "Scalab is an open-source 'low-code' environment. "
            , Html.text "You can design without code and evolve your work into a full web application. "
            , Html.text "However, unlike other solutions, scalab is compatible with traditional, code-driven development workflows. "
            , Html.text "That means everyone in a team that knows how to use tools like Microsoft Powerpoint can participate in the creation of the thing that gets shipped to the user "
            , Html.text "I met my co-founder David Beesley through "
            
            , Html.a [Html.Attributes.href "https://joinef.com"] [Html.text "Entrepreneur First"]
            , Html.text ", 'the world’s leading talent investor'."
            , Html.p [] [
                Html.text "Before Scalab I did work for "
              , Html.a [Html.Attributes.href "https://mercedes-benz.io"] [Html.text "Mercedes-Benz.io"]
              , Html.text " taking responsibility for the success of both customer-facing and internal tools. "
              , Html.text "I fulfilled this responsibility in Stuttgart, Berlin, Lisbon and Singapore. "
              , Html.text "I am grateful for this rich cultural and professional experience."
            ]
        ]
        -- scalab, music, arts
        -- what I did
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
