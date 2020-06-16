module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src)
import Html.Events
import Json.Decode as Decode
import Json.Encode as Encode
import JoyDivision


---- MODEL ----


type alias Model =
    {state : State, fft : List Fft, scroll : Float}

type alias Fft = List Float

type State =
    NotStarted
    | Paused
    | Playing

stateToString state =
    case state of
        NotStarted -> "not-started"
        Paused -> "paused"
        Playing -> "playing"

keyframes =
    { from = {drums = 0, melody = 0.5}
    , over = {drums = 0.8, melody = 1}
    , to = to
    }

to : Frame
to = {drums = 0.8, melody = 0}

-- [generator-start]
type alias Frame = {drums : Float, melody: Float}

-- [generator-generated-start] -- DO NOT MODIFY or remove this line
decodeFrame =
   Decode.map2
      Frame
         ( Decode.field "drums" Decode.float )
         ( Decode.field "melody" Decode.float )

encodeFrame a =
   Encode.object
      [ ("drums", Encode.float a.drums)
      , ("melody", Encode.float a.melody)
      ] 
-- [generator-end]

interpolate : Float -> Frame
interpolate step =
    let
        fn start end position =
            start + ((end - start) * position)
    in
        { drums =
            if step > 0.5
                then fn keyframes.over.drums keyframes.to.drums (step * 2 - 1)
                else fn keyframes.from.drums keyframes.over.drums (step * 2)
        , melody =
            if step > 0.5
                then fn keyframes.over.melody keyframes.to.melody (step * 2 - 1)
                else fn keyframes.from.melody keyframes.over.melody (step * 2)
        }


init : ( Model, Cmd Msg )
init =
    ( {state = Paused, fft = [], scroll = 0}, Cmd.none )

onFft =
    Html.Events.on "fft" decodeFft

decodeFft : Decode.Decoder Msg
decodeFft =
    Decode.field "detail" (Decode.list Decode.float)
    |> Decode.map FftReceived

onScroll =
    Html.Events.on "scrollPct" decodeScroll

decodeScroll : Decode.Decoder Msg
decodeScroll =
    Decode.field "detail" (Decode.float)
    |> Decode.map Scrolled

---- UPDATE ----


type Msg
    = NoOp
    | Play
    | Stop
    | FftReceived (List Float)
    | Scrolled Float



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        Play ->
            ( {model | state = Playing}, Cmd.none )
        Stop ->
            ( {model | state = Paused}, Cmd.none )
        Scrolled pct ->
            ( {model | scroll = pct}, Cmd.none )
        FftReceived fft ->
            ( {model | fft = fft :: model.fft |> List.take 150}, Cmd.none )


quote = Html.p [Html.Attributes.class "quote"] [
    Html.text "I think any time somebody considers what they want from"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "an economy in a situation where technology is getting better and better is"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "the economy to"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "be about subjective values."
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "That's a signal that we are creating technologies and an economy that's really "
    , Html.span [Html.Attributes.class "nowrap"] [Html.text "serving us."]
    ]

-- Jaron Lanier, Making Sense Podcast #135, minute 11

---- VIEW ----

renderStyles {fft} =
    let
        selector index = "path:nth-child(" ++ (String.fromInt index) ++ "n)"
        prop1 val = "transform: rotate(" ++ (String.fromFloat (val / 100)) ++ "deg)"
        renderRule1 index val =  selector index ++ "{" ++ prop2 val ++ "}"
        prop2 val = "stroke-dashoffset: " ++ (String.fromFloat val)
        -- renderRule2 index val = "path:nth-child(" ++ (String.fromInt index) ++ "n) { ++ "}"
        rules =
            fft
            |> List.indexedMap renderRule1
            |> String.join "\n"
--         rules2 =
--             fft
--             |> List.indexedMap renderRule2
--             |> String.join "\n"
    in
        Html.node "style" [] [Html.text (rules)]

visualizer : Fft -> Html Msg
visualizer fft =
    let
        height = Html.Attributes.style "height" "200px"
        bg = Html.Attributes.style "background-color" "red"
        display = Html.Attributes.style "display" "flex"
        alignBottom = Html.Attributes.style "align-items" "flex-end"
        renderBar val =
            let
                width = Html.Attributes.style "width" ((String.fromFloat <| 100 / (List.length fft |> toFloat)) ++ "%")
                bg_ = Html.Attributes.style "background-color" "white"
                offset = Html.Attributes.style "transform" ("translateY(" ++ String.fromFloat val ++ "px)")
            in
                Html.div
                    [height, offset, width, bg_]
                    []
    in
        fft
        |> List.map renderBar
        |> Html.div [height, display, alignBottom]


scrollObserver =
    Html.node "scroll-observer" [onScroll, Html.Attributes.style "display" "none"] []
items = ["/painting-1.jpg", "/painting-2.jpg", "/painting-3.jpg"]
imgs =
    items
    |> List.map (\src -> Html.node "intense-image" [Html.Attributes.class "artwork"] [ Html.img [Html.Attributes.src src] []])

viz : List Fft -> Html JoyDivision.Msg
viz fft =
    let
        joyModel =
            fft
            |> JoyDivision.fromList
    in
    JoyDivision.view joyModel

player model =
    let
        frame = interpolate model.scroll
    in
        Html.section [Html.Attributes.class "player"][
            playButton model
            , Html.node "factory-beat-player"
                [ onFft
                , Html.Attributes.attribute "state" (stateToString model.state)
                , Html.Attributes.attribute "levels" (encodeFrame frame |> Encode.encode 4)
                ] []
        ]

view : Model -> Html Msg
view model =
    Html.article [] <|
        -- intro
        [ viz model.fft |> Html.map (always NoOp)
        , h1 [Html.Attributes.class "title"] [ text "Jan Wirth - Artist Residency application"]
        , quote
        , Html.p [Html.Attributes.class "quote-source"] [
            Html.text "Jaron Lanier, Philosopher, Artist, Technologist"
        ]
        , Html.p [Html.Attributes.class "intro-text"]
            [ Html.text "Hey, my name is Jan. I am a software/design/music crossover entrepreneur."
            , Html.text "You are looking at a interactive music installation handcrafted just for you."
            , Html.text "The general concept of the residency inspires me because I am passionate about technology and its implications for how we think, live and love."
            , Html.text "The topics perfectly match my profile. I am a creative technologist with a background in arts and design."
            , Html.text "Right now, you are looking at a mix between a non-stage live music experience and sound installation. It is composed, designed and hand-coded just for you."
            , Html.text "I want to show how keen I am to work with the most ambitious people in experimental arts and technology and be part of something meaningful. So I put in the work."
            , Html.text "I hope this experience helps you evaluate if and why I should be part of the artist residency program."
            ]
        , scrollObserver
        , player model
        -- what I do
        , Html.h2 [] [Html.text "Art"]
        ]
        ++ imgs ++
        [
          Html.h2 [] [Html.text "Some Projects"]
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

